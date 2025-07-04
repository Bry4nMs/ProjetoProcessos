-- DIAGNÓSTICO COMPLETO DO BUCKET DOCUMENTS
-- Execute este script para identificar problemas

-- =====================================================
-- 1. VERIFICAR SE O BUCKET EXISTE
-- =====================================================

SELECT '=== VERIFICAÇÃO DO BUCKET ===' as secao;

SELECT 
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Bucket documents EXISTE'
    ELSE '❌ Bucket documents NÃO EXISTE'
  END as status_bucket,
  COUNT(*) as total_buckets
FROM storage.buckets 
WHERE id = 'documents';

-- =====================================================
-- 2. VERIFICAR CONFIGURAÇÃO DO BUCKET
-- =====================================================

SELECT '=== CONFIGURAÇÃO DO BUCKET ===' as secao;

SELECT 
  id,
  name,
  public,
  file_size_limit,
  created_at,
  updated_at
FROM storage.buckets 
WHERE id = 'documents';

-- =====================================================
-- 3. VERIFICAR POLÍTICAS DE SEGURANÇA
-- =====================================================

SELECT '=== POLÍTICAS DE SEGURANÇA ===' as secao;

-- Verificar se RLS está habilitado
SELECT 
  CASE 
    WHEN rowsecurity THEN '✅ RLS HABILITADO'
    ELSE '❌ RLS DESABILITADO'
  END as rls_status
FROM pg_tables 
WHERE schemaname = 'storage' 
AND tablename = 'objects';

-- Verificar políticas existentes
SELECT 
  policyname,
  permissive,
  cmd,
  CASE 
    WHEN qual LIKE '%documents%' THEN '✅ Política para documents'
    ELSE '⚠️ Política genérica'
  END as relevancia
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;

-- =====================================================
-- 4. VERIFICAR PERMISSÕES DO USUÁRIO
-- =====================================================

SELECT '=== PERMISSÕES DO USUÁRIO ===' as secao;

-- Verificar usuário atual
SELECT 
  current_user as usuario_atual,
  session_user as sessao_usuario;

-- =====================================================
-- 5. TESTAR ACESSO AO BUCKET
-- =====================================================

SELECT '=== TESTE DE ACESSO ===' as secao;

-- Tentar inserir um arquivo de teste (vai falhar, mas mostra se as políticas estão funcionando)
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM storage.objects 
      WHERE bucket_id = 'documents' 
      LIMIT 1
    ) THEN '✅ Acesso de leitura OK'
    ELSE '⚠️ Acesso de leitura pode ter problemas'
  END as teste_leitura;

-- =====================================================
-- 6. VERIFICAR ARQUIVOS EXISTENTES
-- =====================================================

SELECT '=== ARQUIVOS EXISTENTES ===' as secao;

SELECT 
  COUNT(*) as total_arquivos,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Existem arquivos no bucket'
    ELSE 'ℹ️ Bucket vazio'
  END as status_arquivos
FROM storage.objects 
WHERE bucket_id = 'documents';

-- =====================================================
-- 7. RECOMENDAÇÕES
-- =====================================================

SELECT '=== RECOMENDAÇÕES ===' as secao;

-- Verificar se precisa de correções
SELECT 
  CASE 
    WHEN NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'documents') 
    THEN '❌ EXECUTAR: criar_bucket_documents.sql'
    WHEN NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE tablename = 'objects' 
      AND schemaname = 'storage'
      AND policyname LIKE '%documents%'
    )
    THEN '⚠️ EXECUTAR: verificar_corrigir_bucket.sql'
    ELSE '✅ Bucket parece estar configurado corretamente'
  END as acao_recomendada;

-- =====================================================
-- 8. RESUMO FINAL
-- =====================================================

SELECT '=== RESUMO FINAL ===' as secao;

SELECT 
  'Bucket documents: ' || 
  CASE 
    WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'documents') THEN 'EXISTE'
    ELSE 'NÃO EXISTE'
  END ||
  ' | RLS: ' ||
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_tables 
      WHERE schemaname = 'storage' 
      AND tablename = 'objects' 
      AND rowsecurity
    ) THEN 'HABILITADO'
    ELSE 'DESABILITADO'
  END ||
  ' | Políticas: ' ||
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE tablename = 'objects' 
      AND schemaname = 'storage'
      AND policyname LIKE '%documents%'
    ) THEN 'CONFIGURADAS'
    ELSE 'FALTANDO'
  END as resumo_completo; 