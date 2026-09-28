(function () {
  const THEME_KEY = 'masar-theme';
  const root = document.documentElement;

  function selectedTheme() {
    return localStorage.getItem(THEME_KEY) || 'system';
  }

  function applyTheme(theme) {
    const value = ['light', 'dark', 'system'].includes(theme) ? theme : 'system';
    const dark = value === 'dark' || (value === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);
    root.dataset.theme = dark ? 'dark' : 'light';
    root.dataset.themePreference = value;
    root.style.colorScheme = dark ? 'dark' : 'light';
  }

  applyTheme(selectedTheme());
  const systemTheme = window.matchMedia('(prefers-color-scheme: dark)');
  systemTheme.addEventListener?.('change', () => {
    if (selectedTheme() === 'system') applyTheme('system');
  });

  function roleLabel(role) {
    return ({ user: 'User', department_admin: 'Department Administrator', full_admin: 'Full Administrator' })[role] || role || '—';
  }

  function formatDate(value) {
    if (!value) return '—';
    return new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Riyadh', year: 'numeric', month: 'short', day: 'numeric' }).format(new Date(value));
  }

  function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character]);
  }

  function icon(name) {
    const icons = {
      profile: '<circle cx="12" cy="8" r="4"/><path d="M4.5 21a7.5 7.5 0 0 1 15 0"/>',
      sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.42 1.42M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.42-1.42M17.66 6.34l1.41-1.41"/>',
      lock: '<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
      logout: '<path d="M10 5H6a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h4"/><path d="m15 8 4 4-4 4M19 12H9"/>'
    };
    return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[name]}</svg>`;
  }

  function closeMenus() {
    document.getElementById('account-popover')?.classList.remove('open');
    document.getElementById('account-menu-trigger')?.setAttribute('aria-expanded', 'false');
  }

  function closeModal(id) {
    document.getElementById(id)?.classList.remove('open');
    document.body.classList.remove('account-modal-open');
  }

  function openModal(id) {
    closeMenus();
    document.getElementById(id)?.classList.add('open');
    document.body.classList.add('account-modal-open');
  }

  function profileRows(user) {
    const scope = user.role === 'full_admin' ? 'All departments' : (user.department || 'Not assigned');
    return [
      ['Full name', user.full_name], ['Username', user.username], ['Email', user.email],
      ['Role', roleLabel(user.role)], ['Department / access', scope],
      ['Account status', user.active ? 'Active' : 'Inactive'], ['Registered', formatDate(user.created_at)]
    ].map(([label, value]) => `<div class="account-profile-item"><span>${label}</span><strong>${escapeHtml(value || '—')}</strong></div>`).join('');
  }

  async function initAccountMenu() {
    const trigger = document.getElementById('account-menu-trigger');
    if (!trigger) return;
    const token = sessionStorage.getItem('token');
    if (!token) return;

    let user;
    try {
      const response = await fetch('/api/auth/me', { headers: { Authorization: `Bearer ${token}` } });
      if (!response.ok) return;
      user = (await response.json()).user;
    } catch (_) { return; }

    const initials = String(user.full_name || user.username || 'A').split(/\s+/).slice(0, 2).map(part => part[0]).join('').toUpperCase();
    document.body.insertAdjacentHTML('beforeend', `
      <div class="account-popover" id="account-popover" aria-hidden="true">
        <div class="account-summary"><span class="account-avatar">${escapeHtml(initials)}</span><div><strong>${escapeHtml(user.full_name)}</strong><span>${escapeHtml(user.email)}</span><small>${escapeHtml(roleLabel(user.role))}${user.department ? ` · ${escapeHtml(user.department)}` : ''}</small></div></div>
        <div class="account-menu-list">
          <button type="button" data-account-action="profile">${icon('profile')}<span>My profile</span></button>
          <div class="appearance-row"><span>${icon('sun')}<b>Appearance</b></span><div class="theme-options" role="group" aria-label="Appearance"><button type="button" data-theme="light">Light</button><button type="button" data-theme="dark">Dark</button><button type="button" data-theme="system">System</button></div></div>
          <button type="button" data-account-action="password">${icon('lock')}<span>Change password</span></button>
          <button class="account-signout" type="button" data-account-action="signout">${icon('logout')}<span>Sign out</span></button>
        </div>
      </div>
      <div class="account-modal" id="profile-modal" role="dialog" aria-modal="true" aria-labelledby="profile-title">
        <section class="account-modal-card"><header><div><small>ACCOUNT</small><h2 id="profile-title">My profile</h2><p>Your account details are managed by the system.</p></div><button class="utility-button account-modal-close" type="button" aria-label="Close profile">×</button></header><div class="account-profile-grid">${profileRows(user)}</div><footer><button class="secondary-action account-modal-close" type="button">Close</button><button class="primary-action" type="button" data-account-action="password">Change password</button></footer></section>
      </div>
      <div class="account-modal" id="password-modal" role="dialog" aria-modal="true" aria-labelledby="password-title">
        <section class="account-modal-card account-password-card"><header><div><small>SECURITY</small><h2 id="password-title">Change password</h2><p>Confirm your current password before choosing a new one.</p></div><button class="utility-button account-modal-close" type="button" aria-label="Close password dialog">×</button></header><form id="change-password-form"><label for="current-password">Current password</label><input id="current-password" type="password" autocomplete="current-password" required><label for="new-password">New password</label><input id="new-password" type="password" minlength="8" autocomplete="new-password" required><label for="confirm-password">Confirm new password</label><input id="confirm-password" type="password" minlength="8" autocomplete="new-password" required><div class="account-form-message" id="password-message" aria-live="polite"></div><footer><button class="secondary-action account-modal-close" type="button">Cancel</button><button class="primary-action" type="submit">Update password</button></footer></form></section>
      </div>`);

    const popover = document.getElementById('account-popover');
    const updateThemeButtons = () => document.querySelectorAll('[data-theme]').forEach(button => button.classList.toggle('active', button.dataset.theme === selectedTheme()));
    updateThemeButtons();
    trigger.addEventListener('click', event => {
      event.stopPropagation();
      const opening = !popover.classList.contains('open');
      popover.classList.toggle('open', opening);
      popover.setAttribute('aria-hidden', String(!opening));
      trigger.setAttribute('aria-expanded', String(opening));
    });
    popover.addEventListener('click', event => event.stopPropagation());
    document.addEventListener('click', closeMenus);
    document.addEventListener('keydown', event => {
      if (event.key === 'Escape') { closeMenus(); closeModal('profile-modal'); closeModal('password-modal'); }
    });
    document.querySelectorAll('[data-theme]').forEach(button => button.addEventListener('click', () => {
      localStorage.setItem(THEME_KEY, button.dataset.theme);
      applyTheme(button.dataset.theme);
      updateThemeButtons();
    }));
    document.querySelectorAll('[data-account-action="profile"]').forEach(button => button.addEventListener('click', () => openModal('profile-modal')));
    document.querySelectorAll('[data-account-action="password"]').forEach(button => button.addEventListener('click', () => { closeModal('profile-modal'); openModal('password-modal'); }));
    document.querySelectorAll('[data-account-action="signout"]').forEach(button => button.addEventListener('click', () => { sessionStorage.clear(); location.href = '/login'; }));
    document.querySelectorAll('.account-modal-close').forEach(button => button.addEventListener('click', () => closeModal(button.closest('.account-modal').id)));
    document.querySelectorAll('.account-modal').forEach(modal => modal.addEventListener('click', event => { if (event.target === modal) closeModal(modal.id); }));

    document.getElementById('change-password-form').addEventListener('submit', async event => {
      event.preventDefault();
      const form = event.currentTarget;
      const message = document.getElementById('password-message');
      const submit = form.querySelector('[type="submit"]');
      const currentPassword = document.getElementById('current-password').value;
      const newPassword = document.getElementById('new-password').value;
      const confirmation = document.getElementById('confirm-password').value;
      message.className = 'account-form-message';
      if (newPassword !== confirmation) { message.classList.add('error'); message.textContent = 'New passwords do not match.'; return; }
      submit.disabled = true; message.textContent = 'Updating password…';
      try {
        const response = await fetch('/api/auth/change-password', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ current_password: currentPassword, new_password: newPassword }) });
        const result = await response.json();
        if (!response.ok) throw new Error(result.message || 'Unable to update password');
        form.reset();
        form.querySelectorAll('input, button').forEach(control => { control.disabled = true; });
        message.classList.add('success');
        message.innerHTML = '<strong>Password changed successfully</strong><span>For your security, you’ll be signed out in a moment. Sign in again using your new password.</span>';
        window.setTimeout(() => { sessionStorage.clear(); location.href = '/login'; }, 2000);
      } catch (error) {
        message.classList.add('error'); message.textContent = error.message;
        submit.disabled = false;
      }
    });
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', initAccountMenu);
  else initAccountMenu();
})();
