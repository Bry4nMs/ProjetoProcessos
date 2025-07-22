-- FUNÇÃO PARA RESTAURAR PROCESSOS EXCLUÍDOS (SOFT DELETE)
-- Execute este script no SQL Editor do Supabase

-- Criar função RPC para restaurar processos
CREATE OR REPLACE FUNCTION public.restore_process(processo_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Restaurar o processo (remover o deleted_at)
  UPDATE public.processes
  SET deleted_at = NULL
  WHERE id = processo_id;
  
  -- Registrar na tabela de auditoria
  INSERT INTO public.audit_log (
    process_id,
    user_id,
    field_name,
    old_value,
    new_value
  ) VALUES (
    processo_id,
    auth.uid(),
    'deleted_at',
    'data de exclusão',
    'NULL'
  );
  
  -- Retornar sem erro
  RETURN;
END;
$$;

-- Adicionar comentário à função
COMMENT ON FUNCTION public.restore_process IS 'Restaura um processo que foi excluído via soft delete, definindo deleted_at como NULL e registrando a ação no log de auditoria.';