-- Função RPC para buscar registros de gastos de uma ação
-- Esta função busca todos os registros de gastos combinados de todos os processos de uma ação específica

CREATE OR REPLACE FUNCTION get_records_for_action(p_action_id UUID)
RETURNS TABLE (
  id UUID,
  process_id UUID,
  process_number TEXT,
  process_name TEXT,
  description TEXT,
  amount DECIMAL(15,2),
  record_date DATE,
  record_type TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.process_id,
    p.process_number,
    p.name as process_name,
    r.description,
    r.amount,
    r.record_date,
    r.record_type,
    r.created_at
  FROM records r
  INNER JOIN processes p ON r.process_id = p.id
  WHERE p.action_id = p_action_id
  ORDER BY r.record_date DESC, r.created_at DESC;
END;
$$;

-- Conceder permissões para usuários autenticados
GRANT EXECUTE ON FUNCTION get_records_for_action(UUID) TO authenticated;