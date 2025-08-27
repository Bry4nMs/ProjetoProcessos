-- Função RPC para vincular um processo a uma ação
-- Esta função atualiza o campo action_id de um processo específico

CREATE OR REPLACE FUNCTION link_process_to_action(
  p_process_id UUID,
  p_action_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  process_exists BOOLEAN;
  action_exists BOOLEAN;
BEGIN
  -- Verificar se o processo existe e não está vinculado a outra ação
  SELECT EXISTS(
    SELECT 1 FROM processes 
    WHERE id = p_process_id AND action_id IS NULL
  ) INTO process_exists;
  
  -- Verificar se a ação existe
  SELECT EXISTS(
    SELECT 1 FROM actions 
    WHERE id = p_action_id
  ) INTO action_exists;
  
  -- Se ambos existem, fazer o vínculo
  IF process_exists AND action_exists THEN
    UPDATE processes 
    SET 
      action_id = p_action_id,
      updated_at = NOW()
    WHERE id = p_process_id;
    
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$;

-- Conceder permissões para usuários autenticados
GRANT EXECUTE ON FUNCTION link_process_to_action(UUID, UUID) TO authenticated;