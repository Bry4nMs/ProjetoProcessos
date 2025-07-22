-- Implementação do sistema de RBAC (Role-Based Access Control)

-- 1. Criar tipo enum para os papéis (roles)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE public.user_role AS ENUM ('Admin', 'User');
    END IF;
END $$;

-- 2. Verificar se a tabela profiles existe e criar se não existir
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT,
    telefone TEXT,
    setor_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. Adicionar coluna role (se não existir) e definir como tipo enum
DO $$ 
BEGIN
    -- Primeiro remover a política que depende da coluna role
    EXECUTE 'DROP POLICY IF EXISTS allow_admin_soft_delete ON public.processes';
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'profiles' 
                   AND column_name = 'role') THEN
        -- Se a coluna não existe, adicionar como tipo enum diretamente
        ALTER TABLE public.profiles ADD COLUMN role public.user_role DEFAULT 'User';
    ELSE
        -- Se a coluna já existe, verificar se é do tipo enum
        IF (SELECT data_type FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'profiles' 
            AND column_name = 'role') != 'USER-DEFINED' THEN
            
            -- Primeiro remover o valor padrão
            ALTER TABLE public.profiles ALTER COLUMN role DROP DEFAULT;
            
            -- Converter os valores existentes para o formato correto
            UPDATE public.profiles SET role = 
                CASE 
                    WHEN LOWER(role::text) = 'admin' THEN 'Admin'
                    ELSE 'User'
                END;
                
            -- Alterar o tipo da coluna para o enum usando CAST
            ALTER TABLE public.profiles 
                ALTER COLUMN role TYPE public.user_role 
                USING (role::text::public.user_role);
            
            -- Adicionar o valor padrão novamente
            ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'User'::public.user_role;
        END IF;
    END IF;
END $$;

-- 4. Recriar a política allow_admin_soft_delete com o novo tipo enum
-- Nota: Esta política será recriada novamente no final do script

-- 5. Adicionar coluna status (se não existir)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'profiles' 
                   AND column_name = 'status') THEN
        ALTER TABLE public.profiles ADD COLUMN status TEXT DEFAULT 'ativo';
    END IF;
END $$;

-- 6. Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);

-- 7. Comentários para documentação
COMMENT ON TABLE public.profiles IS 'Perfis de usuários com informações estendidas';
COMMENT ON COLUMN public.profiles.role IS 'Papel do usuário no sistema (Admin, User)';
COMMENT ON COLUMN public.profiles.status IS 'Status do usuário (ativo, inativo)';

-- 8. Criar função RPC para atualizar o papel (role) de um usuário
CREATE OR REPLACE FUNCTION public.update_user_role(user_id UUID, new_role public.user_role)
RETURNS BOOLEAN AS $$
DECLARE
    caller_role public.user_role;
BEGIN
    -- Verificar se o usuário que está chamando a função é um Admin
    SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
    
    IF caller_role != 'Admin' THEN
        RAISE EXCEPTION 'Apenas administradores podem alterar papéis de usuários';
        RETURN FALSE;
    END IF;
    
    -- Atualizar o papel do usuário
    UPDATE public.profiles SET role = new_role WHERE id = user_id;
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Criar função RPC para atualizar o status de um usuário
CREATE OR REPLACE FUNCTION public.update_user_status(user_id UUID, new_status TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    caller_role public.user_role;
BEGIN
    -- Verificar se o usuário que está chamando a função é um Admin
    SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
    
    IF caller_role != 'Admin' THEN
        RAISE EXCEPTION 'Apenas administradores podem alterar o status de usuários';
        RETURN FALSE;
    END IF;
    
    -- Validar o status
    IF new_status NOT IN ('ativo', 'inativo') THEN
        RAISE EXCEPTION 'Status inválido. Use "ativo" ou "inativo"';
        RETURN FALSE;
    END IF;
    
    -- Atualizar o status do usuário
    UPDATE public.profiles SET status = new_status WHERE id = user_id;
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Criar função RPC para atualizar detalhes do perfil de um usuário
CREATE OR REPLACE FUNCTION public.update_user_profile_details(user_id UUID, new_nome TEXT, new_telefone TEXT, new_setor_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    caller_role public.user_role;
BEGIN
    -- Verificar se o usuário que está chamando a função é um Admin
    SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
    
    IF caller_role != 'Admin' THEN
        RAISE EXCEPTION 'Apenas administradores podem alterar detalhes de perfil de outros usuários';
        RETURN FALSE;
    END IF;
    
    -- Atualizar os detalhes do perfil
    UPDATE public.profiles 
    SET 
        nome = COALESCE(new_nome, nome),
        telefone = COALESCE(new_telefone, telefone),
        setor_id = COALESCE(new_setor_id, setor_id)
    WHERE id = user_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Revisar políticas RLS para a tabela processes
-- Política para SELECT (todos os papéis podem ver)
DROP POLICY IF EXISTS "Todos podem ver processos" ON public.processes;
CREATE POLICY "Todos podem ver processos" ON public.processes
    FOR SELECT USING (
        (SELECT status FROM public.profiles WHERE id = auth.uid()) = 'ativo'
    );

-- Política para INSERT (apenas Admin pode inserir)
DROP POLICY IF EXISTS "Usuários autenticados podem inserir processos" ON public.processes;
CREATE POLICY "Admin pode inserir processos" ON public.processes
    FOR INSERT WITH CHECK (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'Admin'
        AND (SELECT status FROM public.profiles WHERE id = auth.uid()) = 'ativo'
    );

-- Política para UPDATE (apenas Admin pode atualizar)
DROP POLICY IF EXISTS "Usuários autenticados podem atualizar processos" ON public.processes;
CREATE POLICY "Admin pode atualizar processos" ON public.processes
    FOR UPDATE USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'Admin'
        AND (SELECT status FROM public.profiles WHERE id = auth.uid()) = 'ativo'
    );

-- Política para DELETE (apenas Admin pode excluir)
DROP POLICY IF EXISTS "Admin pode excluir processos" ON public.processes;
CREATE POLICY "Admin pode excluir processos" ON public.processes
    FOR DELETE USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'Admin'
        AND (SELECT status FROM public.profiles WHERE id = auth.uid()) = 'ativo'
    );

-- 12. Atualizar a política de soft delete para usar o novo tipo enum
DROP POLICY IF EXISTS allow_admin_soft_delete ON public.processes;
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