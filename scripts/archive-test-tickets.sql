ALTER TABLE public.tickets
  ADD COLUMN IF NOT EXISTS archived BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE public.tickets
SET archived = TRUE
WHERE ticket_id LIKE 'G-%'
   OR ticket_id LIKE 'FULL-%'
   OR ticket_id LIKE 'REG-%'
   OR ticket_id LIKE 'FIX-%'
   OR ticket_id LIKE 'E2E-%'
   OR ticket_id IN (
      'T-95160178', 'T-95158679', 'T-95157088', 'T-95155460',
      'T-94864927', 'T-94538998', 'T-94487116', 'T-90095234',
      'T-90093399', 'T-94160985', 'T-90117444'
   );

SELECT COUNT(*) AS archived_test_tickets
FROM public.tickets
WHERE archived = TRUE;
