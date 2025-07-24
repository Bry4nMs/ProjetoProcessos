-- CRIAR BUCKET DOCUMENTS NO SUPABASE STORAGE
-- Execute este script no SQL Editor do Supabase

-- =====================================================
-- 1. CRIAR BUCKET DOCUMENTS
-- =====================================================

-- Criar bucket 'documents' se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents', 
  'documents', 
  true, 
  52428800, -- 50MB limit
  ARRAY[
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
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- =====================================================
-- 2. CONFIGURAR POLÍTICAS DE SEGURANÇA (RLS)
-- =====================================================

-- Política para permitir que todos vejam os arquivos
CREATE POLICY "Todos podem ver arquivos do bucket documents" ON storage.objects
FOR SELECT USING (bucket_id = 'documents');

-- Política para permitir que usuários autenticados façam upload
CREATE POLICY "Usuários autenticados podem inserir arquivos no bucket documents" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'documents' 
  AND auth.uid() IS NOT NULL
);

-- Política para permitir que usuários autenticados deletem arquivos
CREATE POLICY "Usuários autenticados podem deletar arquivos do bucket documents" ON storage.objects
FOR DELETE USING (
  bucket_id = 'documents' 
  AND auth.uid() IS NOT NULL
);

-- Política para permitir que usuários autenticados atualizem arquivos
CREATE POLICY "Usuários autenticados podem atualizar arquivos do bucket documents" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'documents' 
  AND auth.uid() IS NOT NULL
);

-- =====================================================
-- 3. VERIFICAR SE O BUCKET FOI CRIADO
-- =====================================================

-- Verificar se o bucket existe
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'documents';

-- =====================================================
-- 4. VERIFICAR POLÍTICAS CRIADAS
-- =====================================================

-- Verificar políticas do bucket
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
-- 5. CONFIRMAÇÃO FINAL
-- =====================================================

SELECT 'Bucket documents criado e configurado com sucesso!' as status; 