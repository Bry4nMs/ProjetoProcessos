-- CRIAR BUCKET DOCUMENTS - VERSÃO SIMPLES
-- Execute este script no SQL Editor do Supabase

-- =====================================================
-- 1. CRIAR BUCKET DOCUMENTS
-- =====================================================

-- Remover bucket se existir (para recriar)
DELETE FROM storage.buckets WHERE id = 'documents';

-- Criar bucket documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents', 
  'documents', 
  true, 
  52428800, -- 50MB
  ARRAY['application/pdf', 'image/*', 'text/*', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
);

-- =====================================================
-- 2. POLÍTICAS BÁSICAS
-- =====================================================

-- Permitir visualização pública
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT USING (bucket_id = 'documents');

-- Permitir upload para usuários autenticados
CREATE POLICY "Authenticated users can upload" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'documents' AND auth.uid() IS NOT NULL);

-- =====================================================
-- 3. VERIFICAÇÃO
-- =====================================================

-- Verificar se foi criado
SELECT * FROM storage.buckets WHERE id = 'documents';

-- Verificar políticas
SELECT policyname FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

SELECT 'Bucket documents criado!' as resultado; 