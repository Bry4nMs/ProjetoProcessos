-- Atualizar a política allow_admin_soft_delete para usar o novo tipo enum user_role

-- Primeiro, remover a política existente
DROP POLICY IF EXISTS allow_admin_soft_delete ON public.processes;

-- Recriar a política com o novo tipo enum
CREATE POLICY allow_admin_soft_delete ON public.processes 
FOR UPDATE USING (
  auth.role() = 'authenticated' AND (
    (deleted_at IS NULL AND (
      (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'Admin'
      )
    ))
    OR (deleted_at IS NULL)
  )
);