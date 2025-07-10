# 🔧 SOLUÇÃO: ERRO "BUCKET NOT FOUND"

## 🚨 Problema Identificado

O erro `{"statusCode":"404","error":"Bucket not found","message":"Bucket not found"}` indica que o bucket `documents` não existe no Supabase Storage.

## ✅ Soluções Disponíveis

### **OPÇÃO 1: Script Completo (Recomendado)**

Execute o arquivo `criar_bucket_documents.sql` no SQL Editor do Supabase:

1. Acesse o **painel do Supabase**
2. Vá para **SQL Editor**
3. Copie e cole o conteúdo do arquivo `criar_bucket_documents.sql`
4. Clique em **"Run"**

### **OPÇÃO 2: Script Simples (Alternativo)**

Se o primeiro não funcionar, execute `criar_bucket_simples.sql`:

1. Acesse o **painel do Supabase**
2. Vá para **SQL Editor**
3. Copie e cole o conteúdo do arquivo `criar_bucket_simples.sql`
4. Clique em **"Run"**

### **OPÇÃO 3: Interface Gráfica**

1. Acesse o **painel do Supabase**
2. Vá para **Storage** no menu lateral
3. Clique em **"New bucket"**
4. Configure:
   - **Name**: `documents`
   - **Public bucket**: ✅ Marcar
   - **File size limit**: `50MB`
   - **Allowed MIME types**: Deixar vazio (aceita todos)
5. Clique em **"Create bucket"**

## 🔍 Verificações Pós-Criação

### **1. Verificar se o Bucket Existe**

No SQL Editor, execute:

```sql
SELECT * FROM storage.buckets WHERE id = 'documents';
```

**Resultado esperado**: Deve retornar uma linha com os dados do bucket.

### **2. Verificar Políticas de Segurança**

```sql
SELECT policyname FROM pg_policies
WHERE tablename = 'objects'
AND schemaname = 'storage'
AND policyname LIKE '%documents%';
```

**Resultado esperado**: Deve retornar pelo menos 2 políticas (SELECT e INSERT).

### **3. Testar Upload Manual**

1. Vá para **Storage** no painel do Supabase
2. Clique no bucket `documents`
3. Tente fazer upload de um arquivo pequeno
4. Se funcionar, o bucket está configurado corretamente

## 🧪 Teste da Aplicação

Após criar o bucket:

1. **Reinicie a aplicação** (`npm run dev`)
2. **Faça login** na aplicação
3. **Crie um novo processo** com anexo
4. **Verifique se o upload funciona**
5. **Teste a visualização** de documentos

## ⚠️ Problemas Comuns

### **Erro: "Policy violation"**

**Solução**: Execute novamente o script de políticas:

```sql
-- Remover políticas antigas
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;

-- Criar novas políticas
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT USING (bucket_id = 'documents');

CREATE POLICY "Authenticated users can upload" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'documents' AND auth.uid() IS NOT NULL);
```

### **Erro: "Bucket already exists"**

**Solução**: Use o script simples que remove o bucket antes de recriar:

```sql
DELETE FROM storage.buckets WHERE id = 'documents';
```

### **Erro: "Permission denied"**

**Solução**: Verifique se você tem permissões de administrador no projeto Supabase.

## 📋 Checklist de Verificação

- [ ] Bucket `documents` criado
- [ ] Bucket configurado como público
- [ ] Políticas de segurança aplicadas
- [ ] Upload manual funcionando
- [ ] Upload via aplicação funcionando
- [ ] Visualização de documentos funcionando

## 🎯 Próximos Passos

1. **Execute um dos scripts SQL**
2. **Verifique se o bucket foi criado**
3. **Teste o upload na aplicação**
4. **Confirme que tudo está funcionando**

## 📞 Suporte

Se ainda tiver problemas:

1. **Verifique os logs** do console do navegador
2. **Verifique os logs** do Supabase
3. **Teste com um arquivo pequeno** primeiro
4. **Verifique as variáveis de ambiente** do Supabase

---

**🎉 Após seguir estes passos, o erro "Bucket not found" deve ser resolvido!**
