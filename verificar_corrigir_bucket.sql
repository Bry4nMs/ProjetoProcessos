-- VERIFICAR E CORRIGIR CONFIGURAÇÃO DO BUCKET DOCUMENTS
-- Execute este script no SQL Editor do Supabase

-- =====================================================
-- 1. VERIFICAR CONFIGURAÇÃO ATUAL DO BUCKET
-- =====================================================

-- Verificar se o bucket existe e suas configurações
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types,
  created_at
FROM storage.buckets 
WHERE id = 'documents';

-- =====================================================
-- 2. VERIFICAR POLÍTICAS ATUAIS
-- =====================================================

-- Verificar políticas existentes para o bucket documents
SELECT 
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%documents%';

-- =====================================================
-- 3. CORRIGIR CONFIGURAÇÃO DO BUCKET
-- =====================================================

-- Atualizar bucket para garantir que está público
UPDATE storage.buckets 
SET 
  public = true,
  file_size_limit = 52428800, -- 50MB
  allowed_mime_types = ARRAY[
    'application/pdf',
    'image/*',
    'text/*',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/zip',
    'application/x-rar-compressed'
  ]
WHERE id = 'documents';

-- =====================================================
-- 4. REMOVER POLÍTICAS PROBLEMÁTICAS
-- =====================================================

-- Remover políticas antigas que podem estar causando conflito
DROP POLICY IF EXISTS "Todos podem ver arquivos" ON storage.objects;
DROP POLICY IF EXISTS "Usuários autenticados podem inserir arquivos" ON storage.objects;
DROP POLICY IF EXISTS "Usuários autenticados podem deletar arquivos" ON storage.objects;
DROP POLICY IF EXISTS "Todos podem ver arquivos do bucket documents" ON storage.objects;
DROP POLICY IF EXISTS "Usuários autenticados podem inserir arquivos no bucket documents" ON storage.objects;
DROP POLICY IF EXISTS "Usuários autenticados podem deletar arquivos do bucket documents" ON storage.objects;
DROP POLICY IF EXISTS "Usuários autenticados podem atualizar arquivos do bucket documents" ON storage.objects;
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;

-- =====================================================
-- 5. CRIAR NOVAS POLÍTICAS CORRETAS
-- =====================================================

-- Política para permitir que todos vejam os arquivos do bucket documents
CREATE POLICY "documents_select_policy" ON storage.objects
FOR SELECT USING (bucket_id = 'documents');

-- Política para permitir que usuários autenticados façam upload
CREATE POLICY "documents_insert_policy" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'documents' 
  AND auth.uid() IS NOT NULL
);

-- Política para permitir que usuários autenticados deletem arquivos
CREATE POLICY "documents_delete_policy" ON storage.objects
FOR DELETE USING (
  bucket_id = 'documents' 
  AND auth.uid() IS NOT NULL
);

-- Política para permitir que usuários autenticados atualizem arquivos
CREATE POLICY "documents_update_policy" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'documents' 
  AND auth.uid() IS NOT NULL
);

-- =====================================================
-- 6. VERIFICAR SE RLS ESTÁ HABILITADO
-- =====================================================

-- Habilitar RLS na tabela storage.objects se não estiver
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 7. VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar configuração final do bucket
SELECT 'CONFIGURAÇÃO FINAL DO BUCKET:' as info;
SELECT 
  id,
  name,
  public,
  file_size_limit
FROM storage.buckets 
WHERE id = 'documents';

-- Verificar políticas finais
SELECT 'POLÍTICAS CRIADAS:' as info;
SELECT 
  policyname,
  cmd,
  permissive
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%documents%';

-- Verificar se RLS está habilitado
SELECT 'RLS STATUS:' as info;
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'storage' 
AND tablename = 'objects';

SELECT 'Bucket documents configurado e corrigido com sucesso!' as status; 