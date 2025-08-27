-- Função RPC para buscar processos não vinculados a ações
-- Esta função busca processos onde action_id IS NULL e cujo nome ou número SEI corresponda ao termo de busca

CREATE OR REPLACE FUNCTION search_unlinked_processes(p_search_term TEXT)
RETURNS TABLE (
  id UUID,
  name TEXT,
  process_number TEXT,
  description TEXT,
  created_at TIMESTAMPTZ,
  status TEXT,
  progress_percentage INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.process_number,
    p.description,
    p.created_at,
    p.status,
    p.progress_percentage
  FROM processes p
  WHERE 
    p.action_id IS NULL
    AND (
      p.name ILIKE '%' || p_search_term || '%'
      OR p.process_number ILIKE '%' || p_search_term || '%'
    )
  ORDER BY p.created_at DESC
  LIMIT 20;
END;
$$;

-- Conceder permissões para usuários autenticados
GRANT EXECUTE ON FUNCTION search_unlinked_processes(TEXT) TO authenticated;