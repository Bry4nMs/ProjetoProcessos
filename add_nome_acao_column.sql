-- Comando SQL para adicionar a coluna 'nome_acao' à tabela 'processes'
-- Execute este comando no seu banco de dados Supabase

ALTER TABLE public.processes 
ADD COLUMN nome_acao character varying;
 
-- Comentário opcional para documentar a coluna
COMMENT ON COLUMN public.processes.nome_acao IS 'Nome da ação do processo'; 