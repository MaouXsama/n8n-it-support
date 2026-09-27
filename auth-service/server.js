const http = require('http');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.POSTGRES_HOST,
  port: 5432,
  database: process.env.POSTGRES_DB,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  ssl: { rejectUnauthorized: false }
});
const secret = process.env.AUTH_JWT_SECRET || crypto.randomBytes(32).toString('hex');

async function init() {
  await pool.query(`CREATE TABLE IF NOT EXISTS app_users (
    id SERIAL PRIMARY KEY, username VARCHAR(80) UNIQUE NOT NULL, email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL, password_hash TEXT NOT NULL, role VARCHAR(30) NOT NULL DEFAULT 'user',
    department VARCHAR(50), active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );`);
  await pool.query(`ALTER TABLE public.tickets ADD COLUMN IF NOT EXISTS archived BOOLEAN NOT NULL DEFAULT FALSE;`);
  await pool.query(`CREATE TABLE IF NOT EXISTS ticket_reassignments (
    id SERIAL PRIMARY KEY, ticket_id VARCHAR(50) NOT NULL, from_department VARCHAR(50), to_department VARCHAR(50) NOT NULL,
    changed_by INTEGER, reason TEXT, changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );`);
  await pool.query(`CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY, actor_user_id INTEGER, action VARCHAR(80) NOT NULL, ticket_id VARCHAR(50), details JSONB, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );`);
  await pool.query(`CREATE TABLE IF NOT EXISTS ticket_comments (
    id SERIAL PRIMARY KEY, ticket_id VARCHAR(50) NOT NULL, author_user_id INTEGER,
    comment TEXT NOT NULL, internal BOOLEAN NOT NULL DEFAULT FALSE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );`);
  const admins = [
    ['admin','admin@example.com','Full Administrator','full_admin',null],
    ['networkadmin','networkadmin@example.com','Networking Administrator','department_admin','Networking'],
    ['helpdeskadmin','helpdeskadmin@example.com','Helpdesk Administrator','department_admin','IT Helpdesk'],
    ['applicationadmin','applicationadmin@example.com','Software Administrator','department_admin','Software']
  ];
  const defaultHash = await bcrypt.hash(process.env.DEFAULT_ADMIN_PASSWORD || 'N8nAdmin-Demo-2026!', 12);
  for (const a of admins) await pool.query(`INSERT INTO app_users(username,email,full_name,password_hash,role,department) VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT (username) DO NOTHING`, [...a.slice(0,3),defaultHash,a[3],a[4]]);
}

function send(res, status, body) { res.writeHead(status, {'Content-Type':'application/json','Access-Control-Allow-Origin':'*'}); res.end(JSON.stringify(body)); }
function read(req) { return new Promise((resolve,reject)=>{let b='';req.on('data',c=>b+=c);req.on('end',()=>{try{resolve(b?JSON.parse(b):{})}catch(e){reject(e)}})}) }
function token(user) { return jwt.sign({id:user.id,username:user.username,email:user.email,role:user.role,department:user.department}, secret, {expiresIn:'8h'}); }
function authUser(req) { const value=req.headers.authorization||''; if(!value.startsWith('Bearer ')) return null; try{return jwt.verify(value.slice(7),secret)}catch{return null} }
async function triggerCompletionEmail(ticketId) {
  try {
    const response = await fetch('https://n8n-project-dev-2rd4r7.eastus.cloudapp.azure.com/webhook/ticket-status', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ticket_id: ticketId, status: 'Completed'})
    });
    const result = await response.text();
    if (!response.ok) console.error(`Completion email webhook returned HTTP ${response.status}: ${result}`);
    else console.log(`Completion email webhook accepted ${ticketId}: ${result}`);
  } catch (error) {
    console.error('Completion email webhook failed:', error.message);
  }
}

async function handler(req,res) {
  if (req.method === 'OPTIONS') return send(res,204,{});
  try {
    const body = await read(req);
    if (req.method === 'POST' && req.url === '/auth/signup') {
      if (!body.email || !body.password || !body.full_name) return send(res,400,{message:'Name, email, and password are required'});
      const username = String(body.email).split('@')[0].toLowerCase();
      const hash = await bcrypt.hash(body.password, 12);
      const q = await pool.query('INSERT INTO app_users(username,email,full_name,password_hash) VALUES($1,$2,$3,$4) RETURNING id,username,email,full_name,role,department', [username,body.email.toLowerCase(),body.full_name,hash]);
      return send(res,201,{user:q.rows[0],token:token(q.rows[0])});
    }
    if (req.method === 'POST' && req.url === '/auth/login') {
      const q = await pool.query('SELECT * FROM app_users WHERE (LOWER(email)=LOWER($1) OR LOWER(username)=LOWER($1)) AND active=TRUE', [body.login]);
      if (!q.rows[0] || !(await bcrypt.compare(body.password || '', q.rows[0].password_hash))) return send(res,401,{message:'Invalid credentials'});
      const {password_hash,...user}=q.rows[0]; return send(res,200,{user,token:token(user)});
    }
    if (req.method === 'GET' && req.url === '/auth/me') {
      const session=authUser(req); if(!session) return send(res,401,{message:'Authentication required'});
      const q=await pool.query('SELECT id,username,email,full_name,role,department,active FROM app_users WHERE id=$1 AND active=TRUE',[session.id]);
      return q.rows[0]?send(res,200,{user:q.rows[0]}):send(res,401,{message:'User not found'});
    }
    if (req.method === 'GET' && req.url.startsWith('/tickets')) {
      const session=authUser(req); if(!session) return send(res,401,{message:'Authentication required'});
      const url=new URL(req.url,'http://localhost'); const search=url.searchParams.get('search')||''; const page=Math.max(1,Number(url.searchParams.get('page')||1)); const limit=Math.min(100,Math.max(1,Number(url.searchParams.get('limit')||25))); const offset=(page-1)*limit;
      if (url.pathname === '/tickets/notifications') {
        if(session.role!=='full_admin') return send(res,403,{message:'Full admin access required'});
        const n=await pool.query('SELECT n.* FROM public.notifications n JOIN public.tickets t ON t.ticket_id=n.ticket_id WHERE t.archived=FALSE ORDER BY n.sent_at DESC LIMIT 200'); return send(res,200,{notifications:n.rows});
      }
      if (url.pathname === '/tickets/comments' && req.method === 'GET') {
        if(!url.searchParams.get('ticket_id')) return send(res,400,{message:'ticket_id is required'});
        const c=await pool.query('SELECT * FROM ticket_comments WHERE ticket_id=$1 ORDER BY created_at ASC',[url.searchParams.get('ticket_id')]); return send(res,200,{comments:c.rows});
      }
      let q;
      const term=`%${search}%`;
      if (session.role === 'full_admin') q=await pool.query('SELECT * FROM public.tickets WHERE archived=FALSE AND (ticket_id ILIKE $1 OR title ILIKE $1 OR requester ILIKE $1) ORDER BY created_at DESC LIMIT $2 OFFSET $3',[term,limit,offset]);
      else if (session.role === 'department_admin') q=await pool.query('SELECT * FROM public.tickets WHERE archived=FALSE AND department=$1 AND (ticket_id ILIKE $2 OR title ILIKE $2 OR requester ILIKE $2) ORDER BY created_at DESC LIMIT $3 OFFSET $4',[session.department,term,limit,offset]);
      else q=await pool.query('SELECT * FROM public.tickets WHERE archived=FALSE AND LOWER(requester)=LOWER($1) AND (ticket_id ILIKE $2 OR title ILIKE $2) ORDER BY created_at DESC LIMIT $3 OFFSET $4',[session.email,term,limit,offset]);
      return send(res,200,{tickets:q.rows,page,limit});
    }
    if (req.method === 'POST' && req.url === '/tickets/reassign') {
      const session=authUser(req); if(!session || !['full_admin','department_admin'].includes(session.role)) return send(res,403,{message:'Admin access required'});
      if(!body.ticket_id || !['Networking','IT Helpdesk','Software'].includes(body.department)) return send(res,400,{message:'Valid ticket and department are required'});
      const current=await pool.query('SELECT department FROM public.tickets WHERE ticket_id=$1',[body.ticket_id]);
      if(!current.rows[0]) return send(res,404,{message:'Ticket not found'});
      if(session.role==='department_admin' && current.rows[0].department!==session.department) return send(res,403,{message:'Ticket is outside your department'});
      await pool.query('UPDATE public.tickets SET department=$1 WHERE ticket_id=$2',[body.department,body.ticket_id]);
      await pool.query('INSERT INTO ticket_reassignments(ticket_id,from_department,to_department,changed_by,reason) VALUES($1,$2,$3,$4,$5)',[body.ticket_id,current.rows[0].department,body.department,session.id,body.reason||null]);
      await pool.query('INSERT INTO audit_log(actor_user_id,action,ticket_id,details) VALUES($1,$2,$3,$4)',[session.id,'department_reassigned',body.ticket_id,JSON.stringify({from:current.rows[0].department,to:body.department,reason:body.reason||null})]);
      return send(res,200,{success:true,ticket_id:body.ticket_id,department:body.department});
    }
    if (req.method === 'POST' && req.url === '/tickets/complete') {
      const session=authUser(req); if(!session || !['full_admin','department_admin'].includes(session.role)) return send(res,403,{message:'Admin access required'});
      const current=await pool.query('SELECT department FROM public.tickets WHERE ticket_id=$1',[body.ticket_id]);
      if(!current.rows[0]) return send(res,404,{message:'Ticket not found'});
      if(session.role==='department_admin' && current.rows[0].department!==session.department) return send(res,403,{message:'Ticket is outside your department'});
      await pool.query("UPDATE public.tickets SET status='Completed', completed_at=NOW() WHERE ticket_id=$1",[body.ticket_id]);
      await pool.query('INSERT INTO audit_log(actor_user_id,action,ticket_id,details) VALUES($1,$2,$3,$4)',[session.id,'ticket_completed',body.ticket_id,JSON.stringify({resolution:body.resolution||null})]);
      await triggerCompletionEmail(body.ticket_id);
      return send(res,200,{success:true,ticket_id:body.ticket_id,status:'Completed'});
    }
    if (req.method === 'POST' && req.url === '/tickets/status') {
      const session=authUser(req); if(!session || !['full_admin','department_admin'].includes(session.role)) return send(res,403,{message:'Admin access required'});
      const allowed=['Open','In Progress','Completed','Cancelled'];
      if(!body.ticket_id || !allowed.includes(body.status)) return send(res,400,{message:'Invalid status'});
      const current=await pool.query('SELECT department FROM public.tickets WHERE ticket_id=$1',[body.ticket_id]);
      if(!current.rows[0]) return send(res,404,{message:'Ticket not found'});
      if(session.role==='department_admin' && current.rows[0].department!==session.department) return send(res,403,{message:'Ticket is outside your department'});
      await pool.query("UPDATE public.tickets SET status=$1, completed_at=CASE WHEN $2 THEN NOW() ELSE completed_at END WHERE ticket_id=$3",[body.status,body.status==='Completed',body.ticket_id]);
      await pool.query('INSERT INTO audit_log(actor_user_id,action,ticket_id,details) VALUES($1,$2,$3,$4)',[session.id,'status_changed',body.ticket_id,JSON.stringify({status:body.status,resolution:body.resolution||null})]);
      if (body.status === 'Completed') await triggerCompletionEmail(body.ticket_id);
      return send(res,200,{success:true,ticket_id:body.ticket_id,status:body.status});
    }
    if (req.method === 'POST' && req.url === '/tickets/comments') {
      const session=authUser(req); if(!session) return send(res,401,{message:'Authentication required'});
      if(!body.ticket_id || !body.comment) return send(res,400,{message:'Ticket and comment are required'});
      const t=await pool.query('SELECT department,requester FROM public.tickets WHERE ticket_id=$1',[body.ticket_id]); if(!t.rows[0]) return send(res,404,{message:'Ticket not found'});
      if(session.role==='user' && t.rows[0].requester.toLowerCase()!==session.email.toLowerCase()) return send(res,403,{message:'Ticket access denied'});
      if(session.role==='department_admin' && t.rows[0].department!==session.department) return send(res,403,{message:'Ticket is outside your department'});
      const c=await pool.query('INSERT INTO ticket_comments(ticket_id,author_user_id,comment,internal) VALUES($1,$2,$3,$4) RETURNING *',[body.ticket_id,session.id,body.comment,Boolean(body.internal&&session.role!=='user')]); return send(res,201,{comment:c.rows[0]});
    }
    if (req.method === 'GET' && req.url === '/health') {
      await pool.query('SELECT 1'); return send(res,200,{status:'ok',database:'ok',time:new Date().toISOString()});
    }
    if (req.method === 'POST' && req.url === '/admin/users/status') {
      const session=authUser(req); if(!session || session.role!=='full_admin') return send(res,403,{message:'Full admin access required'});
      const q=await pool.query('UPDATE app_users SET active=$1 WHERE id=$2 RETURNING id,username,active',[Boolean(body.active),body.user_id]); return q.rows[0]?send(res,200,{user:q.rows[0]}):send(res,404,{message:'User not found'});
    }
    if (req.method === 'GET' && req.url === '/admin/users') {
      const session=authUser(req); if(!session || session.role!=='full_admin') return send(res,403,{message:'Full admin access required'});
      const q=await pool.query('SELECT id,full_name,username,email,role,department,active,created_at FROM app_users ORDER BY created_at ASC');
      return send(res,200,{users:q.rows});
    }
    if (req.method === 'GET' && req.url === '/audit') {
      const session=authUser(req); if(!session || session.role!=='full_admin') return send(res,403,{message:'Full admin access required'});
      const q=await pool.query('SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 200');
      return send(res,200,{audit:q.rows});
    }
    if (req.method === 'GET' && req.url === '/health') return send(res,200,{status:'ok'});
    return send(res,404,{message:'Not found'});
  } catch (e) { console.error(e); return send(res,500,{message:'Server error'}); }
}

init().then(()=>http.createServer(handler).listen(3000,'0.0.0.0')).catch(e=>{console.error(e);process.exit(1)});
