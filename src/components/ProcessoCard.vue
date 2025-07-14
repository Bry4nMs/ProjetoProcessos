<script setup lang="ts">
import { ref, defineProps, computed, watchEffect, onMounted, onUnmounted, watch } from 'vue'
import { tempoGastoEtapa, tempoTotalProcesso, formatarSegundos } from '../composables/useEtapaTimer'
import { buscarEtapasDoProcesso, registrarEventoHistorico } from '../services/auth'
import { supabase } from '../services/supabase'
import { useAuth } from '../composables/useAuth'
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
}

interface Documento {
  id: string
  filename: string
  file_url: string
  file_size?: number
  mime_type?: string
  storage_path: string
  created_at?: string
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

function abrirDetalhes(e) {
  e.stopPropagation()
  showModal.value = true
  carregarDocumentos()
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
  e.stopPropagation()
  if (!props.processo.id) return

  const { error } = await supabase.rpc('avancar_etapa', { processo_id: props.processo.id })

  if (!error) {
    // Buscar a nova etapa atual para registrar no histórico
    const { data: etapas } = await buscarEtapasDoProcesso(props.processo.id)
    if (etapas && etapas.length > 0) {
      const etapaAtual = etapas.findIndex((e: { is_current: boolean }) => e.is_current)
      if (etapaAtual >= 0 && etapaAtual < etapas.length) {
        const nomeNovaEtapa = etapas[etapaAtual].step_templates?.name || 'Etapa ' + (etapaAtual + 1)
        await registrarEventoHistorico(props.processo.id, `Etapa avançada para "${nomeNovaEtapa}".`)
      }
    }

    await carregarEtapas()
    emit('atualizar-processo')
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

onMounted(() => {
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
</script>

<template>
  <div>
    <!-- Card -->
    <div
      class="bg-white/10 backdrop-blur-md border border-white/20 shadow-xl rounded-xl p-6 mb-6 hover:bg-white/15 hover:scale-105 transition-all relative w-full h-full min-h-[320px]"
    >
      <!-- Remover o botão do canto superior direito -->
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
        <span class="border border-cyan-400/50 text-cyan-300 bg-cyan-500/10 text-xs px-2 py-1 rounded">
          {{ processo.area_code || 'Não definido' }}
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
          Passar Etapa
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
                <span>{{ formatarSegundos(tempoEtapaAtual) }}</span>
              </div>
              <div
                v-else-if="etapa.started_at && etapa.ended_at"
                class="text-xs text-teal-400 font-bold"
              >
                Tempo gasto nessa etapa:
                <span>{{
                  formatarSegundos(tempoGastoEtapa(etapa.started_at, etapa.ended_at))
                }}</span>
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
        <button
          class="absolute top-2 right-2 p-2 rounded-full hover:bg-white/10 text-slate-400 hover:text-teal-400 transition"
          @click="fecharDetalhes"
        >
          <svg xmlns='http://www.w3.org/2000/svg' class='w-6 h-6' fill='none' viewBox='0 0 24 24' stroke='currentColor' stroke-width='2'><path stroke-linecap='round' stroke-linejoin='round' d='M18 6L6 18M6 6l12 12'/></svg>
        </button>

        <!-- Informações do Processo -->
        <div class="mb-6">
          <h2 class="text-2xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent mb-4">
            {{ processo.nome_acao || 'Processo sem nome' }}
          </h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm mb-4">
            <div class="flex justify-between items-center">
              <span class="text-slate-300">Área Temática:</span>
              <span class="bg-teal-600/20 text-teal-300 px-3 py-1 rounded-full text-xs font-semibold">{{ processo.area_code || 'Não definido' }}</span>
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
              <span class="font-bold text-teal-400">{{ formatarValor(processo.valor_inicial_padrao || 0) }}</span>
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
              <span>{{ processo.qtd_itens || 'Não definido' }}</span>
            </div>
          </div>

          <hr class="my-4 bg-white/20 h-px border-0" />

          <div class="mb-4">
            <div class="mb-2"><span class="text-slate-300">Descrição dos Itens:</span> <span class="text-white">{{ processo.descricao_itens || 'Não definido' }}</span></div>
            <div class="mb-2"><span class="text-slate-300">Destinação dos Itens:</span> <span class="text-white">{{ processo.destinacao_itens || 'Não definido' }}</span></div>
          </div>

          <!-- Card Informações Financeiras -->
          <div class="bg-white/5 rounded-lg p-4 mb-4">
            <div class="font-bold text-teal-400 mb-4">Informações Financeiras</div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="bg-white/5 rounded-lg p-4 text-center">
                <div class="text-slate-300 text-xs mb-1">Valor de Rendimentos</div>
                <div class="text-green-400 font-bold text-lg">{{ formatarValor(processo.valor_rendimentos || 0) }}</div>
              </div>
              <div class="bg-white/5 rounded-lg p-4 text-center">
                <div class="text-slate-300 text-xs mb-1">Valor de Economicidade</div>
                <div class="text-blue-400 font-bold text-lg">{{ formatarValor(processo.valor_economicidade || 0) }}</div>
              </div>
              <div class="bg-white/5 rounded-lg p-4 text-center">
                <div class="text-slate-300 text-xs mb-1">Valor Total Destinado</div>
                <div class="text-teal-400 font-bold text-lg">{{ formatarValor(processo.valor_total_destinado || 0) }}</div>
              </div>
            </div>
          </div>

          <div class="mb-4">
            <div class="text-slate-300 mb-1">Descrição Geral:</div>
            <div class="bg-white/5 rounded px-3 py-2 text-white">{{ processo.descricao_geral || 'Não definido' }}</div>
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
            <div
              class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-abyss-primary"
            ></div>
            <p class="mt-2 text-gray-600">Carregando documentos...</p>
          </div>

          <div v-else-if="erroDocumentos" class="text-red-600 text-center py-4">
            {{ erroDocumentos }}
          </div>

          <div v-else-if="documentos.length === 0" class="text-center py-8 text-gray-500">
            <svg
              class="w-16 h-16 mx-auto text-gray-300 mb-4"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            <p class="text-lg font-semibold">Nenhum documento anexado</p>
            <p class="text-sm">Este processo ainda não possui documentos anexados.</p>
          </div>

          <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div
              v-for="documento in documentos"
              :key="documento.id"
              class="bg-white/5 border border-white/10 rounded-lg p-4 flex items-center justify-between gap-4 hover:bg-white/10 transition"
            >
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 bg-teal-600/10 rounded-lg flex items-center justify-center">
                  <svg class="w-6 h-6 text-teal-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                </div>
                <div>
                  <h4 class="font-semibold text-white text-sm">{{ documento.filename }}</h4>
                  <p class="text-xs text-slate-400">
                    {{ formatarTamanhoArquivo(documento.file_size) }}
                  </p>
                  <p class="text-xs text-slate-500">
                    {{
                      documento.created_at
                        ? formatarData(documento.created_at)
                        : 'Documento anexado'
                    }}
                  </p>
                </div>
              </div>
              <div class="flex gap-2">
                <button
                  @click="visualizarArquivo(documento.file_url)"
                  class="px-3 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white text-sm rounded font-semibold hover:from-teal-700 hover:to-cyan-600 transition flex items-center gap-1"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  Visualizar
                </button>
                <button
                  @click="baixarArquivo(documento.file_url, documento.filename)"
                  class="px-3 py-2 border border-white/20 text-slate-300 hover:bg-white/10 bg-transparent text-sm rounded font-semibold transition flex items-center gap-1"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                  Baixar
                </button>
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
      </div>
    </div>
  </div>
</template>
