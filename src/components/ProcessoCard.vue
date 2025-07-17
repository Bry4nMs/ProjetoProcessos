<script setup lang="ts">
import { ref, defineProps, computed, watchEffect, onMounted, onUnmounted, watch, reactive } from 'vue'
import { tempoGastoEtapa, tempoTotalProcesso, formatarSegundos } from '../composables/useEtapaTimer'
import { buscarEtapasDoProcesso, registrarEventoHistorico } from '../services/auth'
import { supabase } from '../services/supabase'
import { useAuth } from '../composables/useAuth'
import { useDropZone } from '@vueuse/core'
const { user, fetchUser } = useAuth()

const showModal = ref(false)
const showEtapas = ref(false)
interface Etapa {
  nome: string
  descricao: string
  cor: string
  started_at?: string
  ended_at?: string
  is_current?: boolean
  step_order?: number
  inicio?: number | null
  fim?: number | null
  accumulated_duration_seconds?: number // <-- Adicionado para tipagem correta
}

interface Documento {
  id: string
  filename: string
  file_url: string
  file_size?: number
  mime_type?: string
  storage_path: string
  created_at?: string
  description?: string
}

const etapas = ref<Etapa[]>([])
const documentos = ref<Documento[]>([])
const etapaAtual = ref(0)
const carregandoEtapas = ref(false)
const carregandoDocumentos = ref(false)
const erroEtapas = ref('')
const erroDocumentos = ref('')
const tempoEtapaAtual = ref(0)
let timerInterval = null

const props = defineProps({
  processo: {
    type: Object,
    required: true,
  },
})

const emit = defineEmits(['atualizar-processo'])

const isFavorited = ref(props.processo.is_favorited)
watch(() => props.processo.is_favorited, (val) => { isFavorited.value = val })

const isEditing = ref(false)
const editableData = reactive({
  qtd_itens: null,
  descricao_itens: '',
  destinacao_itens: '',
  descricao_geral: '',
  valor_inicial_padrao: null,
  valor_rendimentos: null,
  valor_economicidade: null,
  valor_total_destinado: null
})
const editLoading = ref(false)
const editError = ref('')

const novoAnexo = ref<File|null>(null)
const novoAnexoDesc = ref('')
const uploadLoading = ref(false)
const uploadError = ref('')

const dropZoneModalRef = ref<HTMLDivElement | null>(null)
function onModalDrop(files: File[] | null) {
  if (files && files.length > 0) {
    novoAnexo.value = files[0]
  }
}
const dropZoneModal = useDropZone(dropZoneModalRef, { onDrop: onModalDrop })
const isOverModal = dropZoneModal && 'isOver' in dropZoneModal ? dropZoneModal.isOver : ref(false)

// Debug: garantir que iniciarEdicao e salvarAlteracoes são chamados
function iniciarEdicao() {
  console.log('Entrou em iniciarEdicao');
  isEditing.value = true
  Object.assign(editableData, {
    qtd_itens: props.processo.qtd_itens,
    descricao_itens: props.processo.descricao_itens,
    destinacao_itens: props.processo.destinacao_itens,
    descricao_geral: props.processo.descricao_geral,
    valor_inicial_padrao: props.processo.valor_inicial_padrao,
    valor_rendimentos: props.processo.valor_rendimentos,
    valor_economicidade: props.processo.valor_economicidade,
    valor_total_destinado: props.processo.valor_total_destinado
  })
  editError.value = ''
}

async function salvarAlteracoes() {
  console.log('Entrou em salvarAlteracoes', editableData)
  editLoading.value = true
  editError.value = ''
  // Adicionar updated_by com o id do usuário logado
  let usuario = user.value
  if (!usuario) usuario = await fetchUser()
  if (!usuario) {
    editLoading.value = false
    editError.value = 'Usuário não autenticado.'
    return
  }

  // 1. Comparar campos e montar array de alterações
  const camposParaLog = [
    'qtd_itens',
    'descricao_itens',
    'destinacao_itens',
    'descricao_geral',
    'valor_inicial_padrao',
    'valor_rendimentos',
    'valor_economicidade',
    'valor_total_destinado'
  ];
  const alteracoes = [];
  camposParaLog.forEach(campo => {
    if (editableData[campo] !== props.processo[campo]) {
      alteracoes.push({
        campo,
        valor_antigo: props.processo[campo],
        valor_novo: editableData[campo]
      });
    }
  });

  // 2. Atualizar processo normalmente
  const { error } = await supabase
    .from('processes')
    .update({
      qtd_itens: editableData.qtd_itens,
      descricao_itens: editableData.descricao_itens,
      destinacao_itens: editableData.destinacao_itens,
      descricao_geral: editableData.descricao_geral,
      valor_inicial_padrao: editableData.valor_inicial_padrao,
      valor_rendimentos: editableData.valor_rendimentos,
      valor_economicidade: editableData.valor_economicidade,
      valor_total_destinado: editableData.valor_total_destinado,
      updated_by: usuario.id
    })
    .eq('id', props.processo.id)
  editLoading.value = false
  if (!error) {
    // 3. Se houve alterações, registrar log
    if (alteracoes.length > 0) {
      try {
        const logs = alteracoes.map(alt => ({
          process_id: props.processo.id,
          user_id: usuario.id,
          field_name: alt.campo,
          old_value: alt.valor_antigo !== undefined && alt.valor_antigo !== null ? String(alt.valor_antigo) : null,
          new_value: alt.valor_novo !== undefined && alt.valor_novo !== null ? String(alt.valor_novo) : null,
          changed_at: new Date().toISOString()
        }));
        await supabase.from('audit_log').insert(logs);
      } catch (e) {
        console.error('Erro ao registrar log de auditoria:', e)
      }
    }
    isEditing.value = false
    emit('atualizar-processo')
    // Emitir evento global para atualizar timeline
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new Event('refresh-historico'))
    }
  } else {
    console.error('Erro ao salvar alterações:', error)
    editError.value = 'Erro ao salvar alterações: ' + (error.message || error.details || 'Erro desconhecido')
    alert('Erro ao salvar alterações: ' + (error.message || error.details || 'Erro desconhecido'))
  }
}

async function carregarEtapas() {
  carregandoEtapas.value = true
  erroEtapas.value = ''
  etapas.value = []
  etapaAtual.value = 0
  const { data, error } = await buscarEtapasDoProcesso(props.processo.id)
  if (error) {
    erroEtapas.value = 'Erro ao buscar etapas: ' + error.message
  } else if (data && data.length > 0) {
    etapas.value = data.map(
      (e: {
        step_templates?: { name?: string }
        started_at?: string
        ended_at?: string
        is_current?: boolean
        step_order?: number
        accumulated_duration_seconds?: number
      }) => ({
        nome: e.step_templates?.name || '',
        descricao: '', // Adapte se quiser descrição
        cor: '#2196f3', // Adapte se quiser cor
        started_at: e.started_at,
        ended_at: e.ended_at,
        is_current: e.is_current,
        step_order: e.step_order,
        inicio: e.started_at ? new Date(e.started_at).getTime() : null, // Para o timer
        fim: e.ended_at ? new Date(e.ended_at).getTime() : null, // Opcional
        accumulated_duration_seconds: e.accumulated_duration_seconds || 0,
      }),
    )
    etapaAtual.value = data.findIndex((e: { is_current: boolean }) => e.is_current)
    if (etapaAtual.value === -1) etapaAtual.value = 0
  }
  carregandoEtapas.value = false
}

async function carregarDocumentos() {
  carregandoDocumentos.value = true
  erroDocumentos.value = ''
  documentos.value = []

  try {
    // Tentar ordenar por created_at primeiro
    const { data, error } = await supabase
      .from('documents')
      .select('*')
      .eq('process_id', props.processo.id)
      .order('created_at', { ascending: false })

    if (error && error.message.includes('created_at')) {
      // Se created_at não existe, ordenar por id
      const { data: dataFallback, error: errorFallback } = await supabase
        .from('documents')
        .select('*')
        .eq('process_id', props.processo.id)
        .order('id', { ascending: false })

      if (errorFallback) {
        erroDocumentos.value = 'Erro ao buscar documentos: ' + errorFallback.message
      } else if (dataFallback) {
        documentos.value = dataFallback
      }
    } else if (error) {
      erroDocumentos.value = 'Erro ao buscar documentos: ' + error.message
    } else if (data) {
      documentos.value = data
    }
  } catch (err) {
    erroDocumentos.value = 'Erro inesperado ao buscar documentos: ' + (err as Error).message
  }

  carregandoDocumentos.value = false
}

async function adicionarAnexo() {
  if (!novoAnexo.value || novoAnexo.value.size === 0) {
    uploadError.value = 'Selecione um arquivo válido.'
    return
  }
  uploadLoading.value = true
  uploadError.value = ''
  try {
    const file = novoAnexo.value
    // Sanitizar nome do arquivo
    const sanitizedFileName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_')
    const filePath = `${props.processo.id}/${Date.now()}_${sanitizedFileName}`
    // Upload com opções
    const { error: uploadErrorObj } = await supabase.storage.from('documents').upload(filePath, file, { cacheControl: '3600', upsert: false })
    if (uploadErrorObj) throw uploadErrorObj
    // Obter URL pública
    const { data: publicUrlData } = supabase.storage.from('documents').getPublicUrl(filePath)
    // Inserir registro na tabela documents
    const { error: insertError } = await supabase.from('documents').insert([{
      process_id: props.processo.id,
      filename: file.name,
      file_url: publicUrlData.publicUrl,
      file_size: file.size,
      mime_type: file.type,
      storage_path: filePath,
      description: novoAnexoDesc.value
    }])
    if (insertError) {
      // Remover arquivo do storage se o insert falhar
      await supabase.storage.from('documents').remove([filePath])
      throw insertError
    }
    // Atualizar lista de documentos
    await carregarDocumentos()
    novoAnexo.value = null
    novoAnexoDesc.value = ''
  } catch (e: unknown) {
    if (typeof e === 'object' && e && 'message' in e) {
      uploadError.value = (e as { message: string }).message || 'Erro ao anexar o documento.'
    } else {
      uploadError.value = 'Erro ao anexar o documento.'
    }
  } finally {
    uploadLoading.value = false
  }
}

function formatarValor(valor: number | null | undefined) {
  if (valor === null || valor === undefined) return 'R$ 0,00'
  return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

function formatarData(data: string | null | undefined) {
  if (!data) return 'Data não definida'
  return new Date(data).toLocaleDateString('pt-BR')
}

function formatarTamanhoArquivo(bytes: number | undefined) {
  if (!bytes) return 'Tamanho desconhecido'
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  if (bytes === 0) return '0 Bytes'
  const i = Math.floor(Math.log(bytes) / Math.log(1024))
  return Math.round((bytes / Math.pow(1024, i)) * 100) / 100 + ' ' + sizes[i]
}

function abrirEtapas(e) {
  e.stopPropagation()
  showEtapas.value = true
  carregarEtapas()
}

function fecharEtapas() {
  showEtapas.value = false
}

const activeModalTab = ref('detalhes') // 'detalhes' ou 'comentarios'
const comments = ref([])
const newComment = ref('')
const loadingComments = ref(false)
const editingCommentId = ref<string | null>(null)
const editingCommentText = ref('')

async function fetchComments() {
  loadingComments.value = true;
  const { data } = await supabase
    .from('process_comments')
    .select('*, profiles(nome)')
    .eq('process_id', props.processo.id)
    .order('created_at', { ascending: false });
  if (data) comments.value = data;
  loadingComments.value = false;
}
async function postComment() {
  if (!newComment.value.trim()) return;
  const { data: user } = await supabase.auth.getUser();
  if (!user) return;
  await supabase.from('process_comments').insert({
    process_id: props.processo.id,
    user_id: user.user.id,
    comment_text: newComment.value
  });
  newComment.value = '';
  await fetchComments();
}

function startEdit(comment: { id: string; comment_text: string }) {
  editingCommentId.value = comment.id;
  editingCommentText.value = comment.comment_text;
}
function cancelEdit() {
  editingCommentId.value = null;
  editingCommentText.value = '';
}
async function saveComment() {
  if (!editingCommentText.value.trim() || !editingCommentId.value) return;
  await supabase
    .from('process_comments')
    .update({ comment_text: editingCommentText.value })
    .eq('id', editingCommentId.value);
  cancelEdit();
  await fetchComments();
}
async function deleteComment(commentId: string) {
  if (!window.confirm('Tem certeza que deseja excluir este comentário?')) return;
  await supabase
    .from('process_comments')
    .delete()
    .eq('id', commentId);
  await fetchComments();
}

function abrirDetalhes(e) {
  e.stopPropagation();
  activeModalTab.value = 'detalhes';
  showModal.value = true;
  carregarDocumentos();
  fetchComments();
}

function fecharDetalhes() {
  showModal.value = false
}

function visualizarArquivo(url: string) {
  // Abrir arquivo em nova aba
  window.open(url, '_blank')
}

function baixarArquivo(url: string, filename: string) {
  // Criar link temporário para download
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.target = '_blank'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

async function passarEtapa(e) {
  e.stopPropagation();
  if (!props.processo.id) return;

  // Verifica se esta é a última etapa ANTES de chamar o RPC
  const isFinalStep = props.processo.etapaAtual === props.processo.totalEtapas - 1 && props.processo.totalEtapas > 0;

  const { error } = await supabase.rpc('avancar_etapa', { processo_id: props.processo.id });

  if (!error) {
    // Sempre registra o evento, independente do usuário
    if (isFinalStep) {
      await registrarEventoHistorico(props.processo.id, 'Processo Concluído.');
    } else {
      // Buscar o nome da nova etapa e registrar
      const { data: etapas } = await buscarEtapasDoProcesso(props.processo.id);
      if (etapas && etapas.length > 0) {
        const etapaAtualIdx = etapas.findIndex(e => e.is_current);
        if (etapaAtualIdx !== -1) {
          const nomeNovaEtapa = etapas[etapaAtualIdx].step_templates?.name || 'etapa desconhecida';
          await registrarEventoHistorico(props.processo.id, `Etapa avançada para "${nomeNovaEtapa}".`);
        }
      }
    }
    emit('atualizar-processo');
  }
}

const progresso = computed(() => {
  if (etapas.value.length === 0) return 0
  return (etapaAtual.value / (etapas.value.length - 1)) * 100
})

const tempoTotal = computed(() => tempoTotalProcesso(etapas.value))

function startTimer() {
  stopTimer()
  const etapa = etapas.value[etapaAtual.value]
  if (etapa && etapa.started_at && !etapa.ended_at && etapa.is_current) {
    tempoEtapaAtual.value = tempoGastoEtapa(etapa.started_at)
    timerInterval = setInterval(() => {
      tempoEtapaAtual.value = tempoGastoEtapa(etapa.started_at)
    }, 1000)
  }
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval)
    timerInterval = null
  }
}

watchEffect(() => {
  startTimer()
})

// Chamar carregarEtapas ao montar o componente para exibir etapa atual no card
onMounted(() => {
  carregarEtapas()
  startTimer()
})

onUnmounted(() => {
  stopTimer()
})

async function toggleFavorite() {
  let usuario = user.value
  if (!usuario) usuario = await fetchUser()
  if (!usuario) return
  if (isFavorited.value) {
    // Desfavoritar
    await supabase.from('user_favorites').delete().match({ user_id: usuario.id, process_id: props.processo.id })
    isFavorited.value = false
  } else {
    // Favoritar
    await supabase.from('user_favorites').insert({ user_id: usuario.id, process_id: props.processo.id })
    isFavorited.value = true
  }
  emit('atualizar-processo')
}

function onNovoAnexoChange(e: Event) {
  const target = e.target as HTMLInputElement;
  if (target.files && target.files.length > 0) {
    novoAnexo.value = target.files[0];
  } else {
    novoAnexo.value = null;
  }
}

// Função para exclusão de documento
async function excluirDocumento(documento: Documento) {
  // 1. Confirmação do usuário
  if (!window.confirm(`Tem certeza que deseja excluir o arquivo "${documento.filename}"? Esta ação não pode ser desfeita.`)) {
    return;
  }
  try {
    carregandoDocumentos.value = true;
    // 2. Excluir do storage primeiro
    const { error: storageError } = await supabase.storage
      .from('documents')
      .remove([documento.storage_path]);
    if (storageError) {
      throw storageError;
    }
    // 3. Excluir do banco de dados
    const { error: dbError } = await supabase
      .from('documents')
      .delete()
      .eq('id', documento.id);
    if (dbError) {
      throw dbError;
    }
    // 4. Atualizar a interface
    await carregarDocumentos();
  } catch (error) {
    console.error('Erro ao excluir documento:', error);
    alert('Falha ao excluir o documento. Tente novamente.');
  } finally {
    carregandoDocumentos.value = false;
  }
}

async function voltarEtapa() {
  if (!props.processo.id) return;
  const { error } = await supabase.rpc('devolver_etapa', { processo_id_param: props.processo.id });
  if (!error) {
    // Buscar etapas atualizadas
    const { data: etapas } = await buscarEtapasDoProcesso(props.processo.id);
    if (etapas && etapas.length > 0) {
      const etapaAtualIdx = etapas.findIndex(e => e.is_current);
      if (etapaAtualIdx !== -1) {
        const nomeEtapa = etapas[etapaAtualIdx].step_templates?.name || 'etapa desconhecida';
        await registrarEventoHistorico(props.processo.id, `Etapa devolvida para "${nomeEtapa}".`);
      }
    }
    await carregarEtapas();
    emit('atualizar-processo');
  }
}
</script>

<template>
  <div>
    <!-- Card -->
    <div
      class="bg-white/10 backdrop-blur-md border border-white/20 shadow-xl rounded-xl p-6 mb-6 hover:bg-white/15 hover:scale-105 transition-all relative w-full h-full min-h-[350px]"
    >
      <!-- Etapa Atual -->
      <div class="flex items-center justify-center mb-2">
        <svg class="w-5 h-5 mr-2 text-cyan-300" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6l4 2"/></svg>
        <span class="text-sm text-slate-200 font-semibold text-center">
          {{ etapas[etapaAtual]?.nome ? `Etapa Atual: ${etapas[etapaAtual].nome}` : 'Etapa Atual: Não definida' }}
        </span>
      </div>
      <!-- Barra de Progresso -->
      <div class="w-full h-2 bg-white/10 rounded mb-3 overflow-hidden">
        <div
          class="h-2 rounded bg-gradient-to-r from-teal-400 to-cyan-300 transition-all"
          :style="{ width: progresso + '%' }"
        ></div>
      </div>
      <div class="flex items-center justify-between mb-2">
        <span :class="[
          'text-xs font-bold px-3 py-1 rounded-full',
          processo.status === 'Em Andamento'
            ? 'bg-gradient-to-r from-teal-600 to-cyan-500 text-white'
            : 'bg-gradient-to-r from-green-600 to-emerald-500 text-white'
        ]">
          {{ processo.status }}
        </span>
        <button @click.stop="toggleFavorite" :aria-label="isFavorited ? 'Desfavoritar' : 'Favoritar'">
          <svg v-if="isFavorited" xmlns="http://www.w3.org/2000/svg" class="text-red-400 w-6 h-6" fill="currentColor" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41 0.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
          </svg>
          <svg v-else xmlns="http://www.w3.org/2000/svg" class="text-slate-400 hover:text-red-400 cursor-pointer transition-colors w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41 0.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
          </svg>
        </button>
      </div>
      <h2 class="text-xl font-bold text-white mb-1">
        {{ processo.nome_acao || 'Processo sem nome' }}
      </h2>
      <p class="text-slate-300 mb-2">{{ processo.descricao_geral || 'Sem descrição' }}</p>
      <div class="flex items-center gap-2 text-sm text-slate-400 mb-2">
        <svg class="w-4 h-4 text-teal-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a2 2 0 01-2.828 0l-4.243-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
        {{ processo.forca_code || 'Não definido' }}
      </div>
      <div class="text-2xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent mb-2">
        {{ formatarValor(processo.valor_inicial_padrao || 0) }}
      </div>
      <div class="flex flex-wrap gap-2 mb-2">
        <span class="border border-teal-400/50 text-teal-300 bg-teal-500/10 text-xs px-2 py-1 rounded">
          {{ processo.tipo_natureza_despesa || 'Não definido' }}
        </span>
      </div>
      <div class="flex items-center justify-between text-xs text-slate-400 mt-4 border-t border-white/10 pt-2">
        <span>Criado em {{ formatarData(processo.data_encaminhamento_aprovacao || processo.created_at) }}</span>
        <span>Ano FAF: {{ processo.ano_faf || 'Não definido' }}</span>
      </div>
      <!-- Botões de Etapas -->
      <div class="flex gap-2 mt-4">
        <button
          v-if="processo.status !== 'Concluído'"
          class="px-3 py-1 bg-gradient-to-r from-teal-600 to-cyan-500 hover:from-teal-700 hover:to-cyan-600 text-white rounded font-semibold shadow flex-1"
          @click.stop="passarEtapa"
        >
          {{ (processo.etapaAtual === processo.totalEtapas - 1 && processo.totalEtapas > 0) ? 'Concluir Processo' : 'Passar Etapa' }}
        </button>
        <button
          class="px-3 py-1 border border-white/20 text-slate-300 hover:bg-white/10 bg-transparent rounded font-semibold shadow flex-1"
          @click.stop="abrirEtapas"
        >
          Ver Etapas
        </button>
        <button
          class="px-3 py-1 border border-white/20 text-slate-300 hover:bg-white/10 bg-transparent rounded font-semibold shadow flex-1"
          @click.stop="abrirDetalhes"
        >
          Ver Detalhes
        </button>
      </div>
    </div>

    <!-- Modal de Etapas -->
    <div
      v-if="showEtapas"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40"
      @click.self="fecharEtapas"
    >
      <div
        class="bg-gradient-to-br from-slate-900/95 to-blue-900/95 backdrop-blur-md border border-white/20 text-white rounded-xl shadow-2xl p-8 max-w-2xl w-full relative max-h-[80vh] overflow-y-auto"
      >
        <button
          class="absolute top-2 right-2 p-2 rounded-md text-slate-400 hover:text-white hover:bg-white/10 transition-colors"
          @click="fecharEtapas"
        >
          <svg xmlns='http://www.w3.org/2000/svg' class='w-6 h-6' fill='none' viewBox='0 0 24 24' stroke='currentColor' stroke-width='2'><path stroke-linecap='round' stroke-linejoin='round' d='M18 6L6 18M6 6l12 12'/></svg>
        </button>
        <h2 class="text-2xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent mb-2">
          {{ processo.nome_acao || 'Processo sem nome' }}
        </h2>
        <div class="mb-4 text-slate-300">
          Tempo total decorrido:
          <span class="font-semibold">{{ formatarSegundos(tempoTotal) }}</span>
        </div>
        <div class="flex justify-end mb-4">
          <button
            v-if="etapaAtual > 0 && processo.status !== 'Concluído'"
            @click="voltarEtapa"
            class="px-4 py-2 bg-gradient-to-r from-cyan-500 to-teal-500 text-white rounded-lg font-semibold shadow hover:from-cyan-600 hover:to-teal-600 transition"
          >
            Voltar à Etapa Anterior
          </button>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            v-for="(etapa, idx) in etapas"
            :key="idx"
            class="flex items-start gap-3 p-3 rounded-lg border border-white/20 bg-white/10 shadow-sm relative"
            :class="{ 'border-teal-400 bg-teal-600/10': idx === etapaAtual }"
          >
            <!-- Círculo colorido -->
            <div
              class="w-8 h-8 rounded-full flex items-center justify-center border-2"
              :style="{
                borderColor: idx <= etapaAtual ? '#14b8a6' : '#334155',
                background: idx < etapaAtual ? 'linear-gradient(to right, #14b8a6cc, #06b6d4cc)' : '#1e293b',
                color: idx < etapaAtual ? '#fff' : '#14b8a6',
              }"
            >
              <span class="font-bold">{{ idx + 1 }}</span>
            </div>
            <div class="flex-1">
              <div class="font-semibold text-white">{{ etapa.nome }}</div>
              <div class="text-xs text-slate-400 mb-1">{{ etapa.descricao }}</div>
              <div
                v-if="idx === etapaAtual && etapa.started_at && !etapa.ended_at && etapa.is_current"
                class="text-xs text-teal-400 font-bold"
              >
                Tempo nesta etapa:
                <span>{{ formatarSegundos((etapa.accumulated_duration_seconds || 0) + Math.floor((Date.now() - new Date(etapa.started_at).getTime()) / 1000)) }}</span>
              </div>
              <div
                v-else-if="etapa.started_at && etapa.ended_at"
                class="text-xs text-teal-400 font-bold"
              >
                Tempo gasto nessa etapa:
                <span>{{ formatarSegundos(etapa.accumulated_duration_seconds || 0) }}</span>
              </div>
            </div>
            <div
              v-if="idx === etapaAtual && etapa.is_current"
              class="absolute top-2 right-2 text-xs font-bold text-teal-400"
            >
              ATUAL
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Detalhes com Documentos -->
    <div
      v-if="showModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40"
      @click.self="fecharDetalhes"
    >
      <div
        class="bg-gradient-to-br from-slate-900/95 to-blue-900/95 backdrop-blur-md border border-white/20 text-white rounded-xl shadow-2xl p-8 max-w-4xl w-full relative max-h-[90vh] overflow-y-auto"
      >
        <!-- Painel de Controle dos Botões e Abas -->
        <div class="absolute top-4 right-6 flex items-center gap-4 z-20">
          <button
            @click.stop="isEditing ? salvarAlteracoes() : iniciarEdicao()"
            class="p-2 rounded-full hover:bg-white/10 text-slate-400 hover:text-teal-400 transition flex items-center"
            :disabled="editLoading"
            title="Atualizar Dados"
          >
            <svg v-if="!isEditing" class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 20h9" /><path stroke-linecap="round" stroke-linejoin="round" d="M16.5 3.5a2.121 2.121 0 113 3L7 19.5 3 21l1.5-4L16.5 3.5z" /></svg>
            <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" /></svg>
          </button>
          <button
            @click="fecharDetalhes"
            class="p-2 rounded-full hover:bg-white/10 text-slate-400 hover:text-red-400 transition"
            title="Fechar"
          >
            <svg xmlns='http://www.w3.org/2000/svg' class='w-6 h-6' fill='none' viewBox='0 0 24 24' stroke='currentColor' stroke-width='2'><path stroke-linecap='round' stroke-linejoin='round' d='M18 6L6 18M6 6l12 12'/></svg>
          </button>
        </div>
        <!-- Abas -->
        <div class="flex gap-2 mb-4 mt-2">
          <button @click="activeModalTab = 'detalhes'" :class="['p-2 rounded transition', activeModalTab === 'detalhes' ? 'text-teal-400 bg-white/10 font-bold' : 'text-slate-400 hover:text-teal-400']" title="Detalhes">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M4 16V4a2 2 0 012-2h8a2 2 0 012 2v12M4 20h16M8 20v-4a2 2 0 012-2h4a2 2 0 012 2v4"/></svg>
          </button>
          <button @click="activeModalTab = 'comentarios'" :class="['p-2 rounded transition', activeModalTab === 'comentarios' ? 'text-teal-400 bg-white/10 font-bold' : 'text-slate-400 hover:text-teal-400']" title="Comentários">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
          </button>
        </div>
        <!-- Conteúdo das Abas -->
        <div v-if="activeModalTab === 'detalhes'">
        <div class="flex items-center gap-2 mb-4">
          <h2 class="text-2xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">
            {{ processo.nome_acao || 'Processo sem nome' }}
          </h2>
        </div>

        <!-- Informações do Processo -->
        <div class="mb-6">

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm mb-4">
            <div class="flex justify-between items-center">
              <span class="text-slate-300">Área Temática:</span>
              <span class="bg-teal-600/20 text-teal-300 px-3 py-1 rounded-full text-xs font-semibold">{{ processo.thematic_area_id || 'Não definido' }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-slate-300">Ano do FAF:</span>
              <span>{{ processo.ano_faf || 'Não definido' }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-slate-300">Tipo de Natureza:</span>
              <span class="text-white">{{ processo.tipo_natureza_despesa || 'Não definido' }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-slate-300">Força Responsável:</span>
              <span>{{ processo.forca_code || 'Não definido' }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-slate-300">Valor Inicial:</span>
              <span v-if="!isEditing" class="font-bold text-teal-400">{{ formatarValor(processo.valor_inicial_padrao || 0) }}</span>
              <input v-else v-model.number="editableData.valor_inicial_padrao" type="number" class="bg-white/10 border border-white/20 rounded px-2 py-1 w-32 text-teal-400 font-bold" />
            </div>
            <div class="flex justify-between items-center">
              <span class="text-slate-300">Data de Encaminhamento:</span>
              <span>{{ formatarData(processo.data_encaminhamento_aprovacao || processo.created_at) }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-slate-300">Processo SEI:</span>
              <span>{{ processo.codigo_transferegov || 'Não definido' }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-slate-300">Quantidade de Itens:</span>
              <span v-if="!isEditing">{{ processo.qtd_itens || 'Não definido' }}</span>
              <input v-else v-model="editableData.qtd_itens" type="number" class="bg-white/10 border border-white/20 rounded px-2 py-1 w-24 text-white" />
            </div>
          </div>

          <hr class="my-4 bg-white/20 h-px border-0" />

          <div class="mb-4">
            <div class="mb-2"><span class="text-slate-300">Descrição dos Itens:</span> <span class="text-white" v-if="!isEditing">{{ processo.descricao_itens || 'Não definido' }}</span><textarea v-else v-model="editableData.descricao_itens" class="bg-white/10 border border-white/20 rounded px-2 py-1 w-full text-white"></textarea></div>
            <div class="mb-2"><span class="text-slate-300">Destinação dos Itens:</span> <span class="text-white" v-if="!isEditing">{{ processo.destinacao_itens || 'Não definido' }}</span><textarea v-else v-model="editableData.destinacao_itens" class="bg-white/10 border border-white/20 rounded px-2 py-1 w-full text-white"></textarea></div>
          </div>

          <!-- Card Informações Financeiras -->
          <div class="bg-white/5 rounded-lg p-4 mb-4">
            <div class="font-bold text-teal-400 mb-4">Informações Financeiras</div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="bg-white/5 rounded-lg p-4 text-center">
                <div class="text-slate-300 text-xs mb-1">Valor de Rendimentos</div>
                <div v-if="!isEditing" class="text-green-400 font-bold text-lg">{{ formatarValor(processo.valor_rendimentos || 0) }}</div>
                <input v-else v-model.number="editableData.valor_rendimentos" type="number" class="bg-white/10 border border-white/20 rounded px-2 py-1 w-full text-green-400 font-bold text-lg" />
              </div>
              <div class="bg-white/5 rounded-lg p-4 text-center">
                <div class="text-slate-300 text-xs mb-1">Valor de Economicidade</div>
                <div v-if="!isEditing" class="text-blue-400 font-bold text-lg">{{ formatarValor(processo.valor_economicidade || 0) }}</div>
                <input v-else v-model.number="editableData.valor_economicidade" type="number" class="bg-white/10 border border-white/20 rounded px-2 py-1 w-full text-blue-400 font-bold text-lg" />
              </div>
              <div class="bg-white/5 rounded-lg p-4 text-center">
                <div class="text-slate-300 text-xs mb-1">Valor Total Destinado</div>
                <div v-if="!isEditing" class="text-teal-400 font-bold text-lg">{{ formatarValor(processo.valor_total_destinado || 0) }}</div>
                <input v-else v-model.number="editableData.valor_total_destinado" type="number" class="bg-white/10 border border-white/20 rounded px-2 py-1 w-full text-teal-400 font-bold text-lg" />
              </div>
            </div>
          </div>

          <div class="mb-4">
            <div class="text-slate-300 mb-1">Descrição Geral:</div>
            <div v-if="!isEditing" class="bg-white/5 rounded px-3 py-2 text-white">{{ processo.descricao_geral || 'Não definido' }}</div>
            <textarea v-else v-model="editableData.descricao_geral" class="bg-white/10 border border-white/20 rounded px-2 py-1 w-full text-white"></textarea>
          </div>
        </div>

        <hr class="my-4 bg-white/20 h-px border-0" />

        <!-- Seção de Documentos -->
        <div class="pt-2">
          <h3 class="text-lg font-bold text-teal-400 mb-4 flex items-center gap-2">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            Documentos Anexados
          </h3>

          <div v-if="carregandoDocumentos" class="text-center py-4">
            <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-teal-400"></div>
          </div>
          <div v-else-if="erroDocumentos" class="text-red-400 text-center py-4">
            {{ erroDocumentos }}
          </div>
          <div v-else-if="documentos.length === 0" class="text-center py-8 text-slate-500">
            <svg class="w-16 h-16 mx-auto text-slate-600 mb-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            <p class="font-semibold">Nenhum documento anexado.</p>
          </div>
          <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div v-for="documento in documentos" :key="documento.id" class="bg-white/5 border border-white/10 rounded-lg p-4 flex flex-col justify-between hover:bg-white/10 transition">
                <div class="flex items-start gap-3 flex-1">
                    <div class="w-10 h-10 bg-teal-600/10 rounded-lg flex-shrink-0 flex items-center justify-center mt-1">
                        <svg class="w-6 h-6 text-teal-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                    </div>
                    <div class="flex flex-col flex-1 min-w-0">
                        <h4 class="font-semibold text-white text-sm break-words">{{ documento.filename }}</h4>
                        <p v-if="documento.description" class="text-xs text-slate-300 mt-1 italic break-words">"{{ documento.description }}"</p>
                        <p class="text-xs text-slate-400 mt-1">{{ formatarTamanhoArquivo(documento.file_size) }}</p>
                        <p class="text-xs text-slate-500 mt-1">{{ documento.created_at ? formatarData(documento.created_at) : 'Documento anexado' }}</p>
                    </div>
                </div>
                <div class="flex gap-2 mt-4 self-end">
                    <button @click="visualizarArquivo(documento.file_url)" class="px-3 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white text-sm rounded font-semibold hover:from-teal-700 hover:to-cyan-600 transition flex items-center gap-1">Visualizar</button>
                    <button @click="baixarArquivo(documento.file_url, documento.filename)" class="px-3 py-2 border border-white/20 text-slate-300 hover:bg-white/10 bg-transparent text-sm rounded font-semibold transition flex items-center gap-1">Baixar</button>
                      <button
                        @click="excluirDocumento(documento)"
                        class="p-2 border border-red-500/50 text-red-400 hover:bg-red-500/20 bg-transparent rounded font-semibold transition flex items-center"
                        title="Excluir Documento"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 6l3 18h6l3-18H3zM5 6h14M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m-6 6v6m4-6v6"></path></svg>
                      </button>
                </div>
            </div>
          </div>

          <div class="mt-6 pt-6 border-t border-white/10">
            <h4 class="font-semibold text-white mb-3">Adicionar Novo Anexo</h4>
            <div class="space-y-4">

                <div
                  ref="dropZoneModalRef"
                  class="p-4 border-2 border-dashed rounded-lg transition-colors"
                  :class="isOverModal ? 'border-teal-400 bg-teal-500/10' : 'border-white/20'"
                >
              <div class="flex items-center gap-4">
                <label for="novo-anexo-input" class="px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white font-semibold cursor-pointer hover:bg-white/20 transition">
                  Escolher arquivo
                </label>
                <input id="novo-anexo-input" type="file" @change="onNovoAnexoChange" class="hidden" />
                    <span class="text-sm text-slate-300 truncate">{{ novoAnexo?.name || 'Arraste um arquivo aqui...' }}</span>
                  </div>
              </div>
              <textarea
                v-model="novoAnexoDesc"
                placeholder="Descrição do anexo (opcional)"
                rows="2"
                class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-400"
              ></textarea>

              <div class="flex items-center gap-4">
                <button
                  @click="adicionarAnexo"
                  :disabled="uploadLoading || !novoAnexo"
                  class="px-5 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded-lg font-semibold shadow disabled:opacity-50 disabled:cursor-not-allowed transition"
                >
                  Anexar
                </button>
                <div v-if="uploadLoading" class="w-5 h-5 border-b-2 border-white rounded-full animate-spin"></div>
                <span v-if="uploadError" class="text-red-400 text-sm">{{ uploadError }}</span>
              </div>

            </div>
          </div>
        </div>

        <div class="flex justify-end mt-6">
          <button
            class="px-4 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded font-bold shadow hover:from-teal-700 hover:to-cyan-600 transition"
            @click="fecharDetalhes"
          >
            Fechar
          </button>
        </div>
        <div v-if="editError" class="text-red-500 text-sm mt-2">{{ editError }}</div>
        </div>
        <div v-else-if="activeModalTab === 'comentarios'">
          <div class="mb-4">
            <h3 class="text-lg font-bold text-teal-400 mb-2 flex items-center gap-2">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
              Comentários do Processo
            </h3>
            <div v-if="loadingComments" class="text-center py-4">
              <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-teal-400"></div>
            </div>
            <div v-else-if="comments.length === 0" class="text-slate-400 text-center py-4">
              Nenhum comentário ainda.
            </div>
            <div v-else class="space-y-4 max-h-64 overflow-y-auto">
              <div v-for="comment in comments" :key="comment.id" class="flex items-start gap-3 py-3 border-b border-white/10">
                <div class="flex-shrink-0 w-10 h-10 bg-slate-700 rounded-full flex items-center justify-center font-bold">
                  {{ comment.profiles?.nome?.charAt(0) || 'U' }}
                </div>
                <div class="flex-1">
                  <div class="flex justify-between items-center">
                    <p class="font-semibold text-white">{{ comment.profiles?.nome || 'Usuário' }}</p>
                    <div v-if="user && user.id === comment.user_id && editingCommentId !== comment.id" class="flex items-center gap-2">
                      <button @click="startEdit(comment)" title="Editar">
                        <svg class="w-4 h-4 text-slate-400 hover:text-teal-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536M9 11l6 6M3 17v4h4l10.293-10.293a1 1 0 00-1.414-1.414L3 17z"/></svg>
                      </button>
                      <button @click="deleteComment(comment.id)" title="Excluir">
                        <svg class="w-4 h-4 text-slate-400 hover:text-red-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg>
                      </button>
                    </div>
                  </div>
                  <p class="text-xs text-slate-500">{{ formatarData(comment.created_at) }}</p>
                  <div v-if="editingCommentId !== comment.id" class="text-slate-200 mt-2 whitespace-pre-wrap">
                    {{ comment.comment_text }}
                  </div>
                  <div v-else class="mt-2">
                    <textarea v-model="editingCommentText" rows="3" class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white text-sm"></textarea>
                    <div class="flex gap-2 mt-2">
                      <button @click="saveComment" class="px-3 py-1 bg-teal-600 text-white rounded font-bold">Salvar</button>
                      <button @click="cancelEdit" class="px-3 py-1 bg-slate-600 text-white rounded font-bold">Cancelar</button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="mt-6">
              <textarea v-model="newComment" rows="2" placeholder="Escreva um comentário..." class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-400"></textarea>
              <div class="flex justify-end mt-2">
                <button @click="postComment" :disabled="!newComment.trim()" class="px-4 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded font-bold shadow disabled:opacity-50 disabled:cursor-not-allowed transition">Enviar</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
