<script setup lang="ts">
import { ref, defineProps, computed, watchEffect, onMounted, onUnmounted } from 'vue'
import { tempoGastoEtapa, tempoTotalProcesso, formatarSegundos } from '../composables/useEtapaTimer'
import { buscarEtapasDoProcesso, registrarEventoHistorico } from '../services/auth'
import { supabase } from '../services/supabase'

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
</script>

<template>
  <div>
    <!-- Card -->
    <div
      class="bg-white rounded-xl shadow-lg p-6 mb-6 hover:shadow-2xl transition relative border border-abyss-deep w-full h-full min-h-[320px]"
    >
      <!-- Barra de Progresso -->
      <div class="w-full h-2 bg-gray-200 rounded mb-3 overflow-hidden">
        <div
          class="h-2 rounded bg-abyss-primary transition-all"
          :style="{ width: progresso + '%' }"
        ></div>
      </div>
      <div class="flex items-center justify-between mb-2">
        <span class="bg-green-100 text-green-700 text-xs font-bold px-3 py-1 rounded-full">{{
          processo.status
        }}</span>
        <span class="text-gray-400 text-xl">&#9825;</span>
      </div>
      <h2 class="text-xl font-bold text-abyss-dark mb-1">
        {{ processo.nome_acao || 'Processo sem nome' }}
      </h2>
      <p class="text-gray-600 mb-2">{{ processo.descricao_geral || 'Sem descrição' }}</p>
      <div class="flex items-center gap-2 text-sm text-gray-500 mb-2">
        <span class="inline-flex items-center gap-1">
          <svg
            class="w-4 h-4 text-abyss-primary"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M17.657 16.657L13.414 20.9a2 2 0 01-2.828 0l-4.243-4.243a8 8 0 1111.314 0z"
            />
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
            />
          </svg>
          {{ processo.forca_code || 'Não definido' }}
        </span>
      </div>
      <div class="flex items-center gap-2 mb-2">
        <span class="text-green-700 font-bold text-lg">{{
          formatarValor(processo.valor_inicial_padrao || 0)
        }}</span>
      </div>
      <div class="flex flex-wrap gap-2 mb-2">
        <span class="bg-abyss-primary/10 text-abyss-primary text-xs px-2 py-1 rounded">{{
          processo.tipo_natureza_despesa || 'Não definido'
        }}</span>
        <span class="bg-abyss-primary/10 text-abyss-primary text-xs px-2 py-1 rounded">{{
          processo.area_code || 'Não definido'
        }}</span>
      </div>
      <div class="flex items-center justify-between text-xs text-gray-500 mt-4">
        <span
          >Criado em
          {{ formatarData(processo.data_encaminhamento_aprovacao || processo.created_at) }}</span
        >
        <span>Ano FAF: {{ processo.ano_faf || 'Não definido' }}</span>
      </div>
      <!-- Botões de Etapas -->
      <div class="flex gap-2 mt-4">
        <button
          v-if="processo.status !== 'Concluído'"
          class="px-3 py-1 bg-abyss-primary text-white rounded font-semibold shadow hover:bg-abyss-secondary transition"
          @click.stop="passarEtapa"
        >
          Passar Etapa
        </button>
        <button
          class="px-3 py-1 bg-gray-200 text-abyss-dark rounded font-semibold shadow hover:bg-gray-300 transition"
          @click.stop="abrirEtapas"
        >
          Ver Etapas
        </button>
        <button
          class="px-3 py-1 bg-gray-100 text-abyss-dark rounded font-semibold shadow hover:bg-gray-200 transition"
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
        class="bg-white rounded-xl shadow-xl p-8 max-w-2xl w-full relative max-h-[80vh] overflow-y-auto"
      >
        <button
          class="absolute top-2 right-2 text-gray-400 hover:text-abyss-primary text-2xl"
          @click="fecharEtapas"
        >
          &times;
        </button>
        <h2 class="text-2xl font-bold text-abyss-primary mb-2">
          {{ processo.nome_acao || 'Processo sem nome' }}
        </h2>
        <div class="mb-4 text-gray-600">
          Tempo total decorrido:
          <span class="font-semibold">{{ formatarSegundos(tempoTotal) }}</span>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            v-for="(etapa, idx) in etapas"
            :key="idx"
            class="flex items-start gap-3 p-3 rounded-lg border border-gray-200 relative"
            :class="{ 'border-abyss-primary bg-abyss-primary/10': idx === etapaAtual }"
          >
            <!-- Círculo colorido -->
            <div
              class="w-8 h-8 rounded-full flex items-center justify-center border-2"
              :style="{
                borderColor: idx <= etapaAtual ? etapa.cor : '#e5e7eb',
                background: idx < etapaAtual ? etapa.cor : '#fff',
                color: idx < etapaAtual ? '#fff' : etapa.cor,
              }"
            >
              <span class="font-bold">{{ idx + 1 }}</span>
            </div>
            <div class="flex-1">
              <div class="font-semibold text-abyss-dark">{{ etapa.nome }}</div>
              <div class="text-xs text-gray-500 mb-1">{{ etapa.descricao }}</div>
              <div
                v-if="idx === etapaAtual && etapa.started_at && !etapa.ended_at && etapa.is_current"
                class="text-xs text-abyss-primary font-bold"
              >
                Tempo nesta etapa:
                <span>{{ formatarSegundos(tempoEtapaAtual) }}</span>
              </div>
              <div
                v-else-if="etapa.started_at && etapa.ended_at"
                class="text-xs text-abyss-primary font-bold"
              >
                Tempo gasto nessa etapa:
                <span>{{
                  formatarSegundos(tempoGastoEtapa(etapa.started_at, etapa.ended_at))
                }}</span>
              </div>
            </div>
            <div
              v-if="idx === etapaAtual && etapa.is_current"
              class="absolute top-2 right-2 text-xs font-bold text-abyss-primary"
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
    >
      <div
        class="bg-white rounded-xl shadow-xl p-8 max-w-4xl w-full relative max-h-[90vh] overflow-y-auto"
      >
        <button
          class="absolute top-2 right-2 text-gray-400 hover:text-abyss-primary text-2xl"
          @click="fecharDetalhes"
        >
          &times;
        </button>

        <!-- Informações do Processo -->
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-abyss-dark mb-4">
            {{ processo.nome_acao || 'Processo sem nome' }}
          </h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div><b>Área Temática:</b> {{ processo.area_code || 'Não definido' }}</div>
            <div><b>Ano do FAF:</b> {{ processo.ano_faf || 'Não definido' }}</div>
            <div>
              <b>Tipo de Natureza:</b> {{ processo.tipo_natureza_despesa || 'Não definido' }}
            </div>
            <div><b>Força Responsável:</b> {{ processo.forca_code || 'Não definido' }}</div>
            <div><b>Valor Inicial:</b> {{ formatarValor(processo.valor_inicial_padrao || 0) }}</div>
            <div>
              <b>Data de Encaminhamento:</b>
              {{ formatarData(processo.data_encaminhamento_aprovacao || processo.created_at) }}
            </div>
            <div>
              <b>Código Transferegov:</b> {{ processo.codigo_transferegov || 'Não definido' }}
            </div>
            <div><b>Quantidade de Itens:</b> {{ processo.qtd_itens || 'Não definido' }}</div>
          </div>

          <div class="mt-4">
            <div><b>Descrição dos Itens:</b> {{ processo.descricao_itens || 'Não definido' }}</div>
            <div class="mt-2">
              <b>Destinação dos Itens:</b> {{ processo.destinacao_itens || 'Não definido' }}
            </div>
            <div class="mt-2">
              <b>Valor de Rendimentos:</b> {{ formatarValor(processo.valor_rendimentos || 0) }}
            </div>
            <div class="mt-2">
              <b>Valor de Economicidade:</b> {{ formatarValor(processo.valor_economicidade || 0) }}
            </div>
            <div class="mt-2">
              <b>Valor Total Destinado:</b> {{ formatarValor(processo.valor_total_destinado || 0) }}
            </div>
            <div class="mt-2">
              <b>Descrição Geral:</b> {{ processo.descricao_geral || 'Não definido' }}
            </div>
          </div>
        </div>

        <!-- Seção de Documentos -->
        <div class="border-t pt-6">
          <h3 class="text-xl font-bold text-abyss-dark mb-4 flex items-center gap-2">
            <svg
              class="w-6 h-6 text-abyss-primary"
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
              class="border border-gray-200 rounded-lg p-4 hover:shadow-md transition"
            >
              <div class="flex items-start justify-between mb-3">
                <div class="flex items-center gap-3">
                  <div
                    class="w-10 h-10 bg-abyss-primary/10 rounded-lg flex items-center justify-center"
                  >
                    <svg
                      class="w-6 h-6 text-abyss-primary"
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
                  </div>
                  <div>
                    <h4 class="font-semibold text-abyss-dark text-sm">{{ documento.filename }}</h4>
                    <p class="text-xs text-gray-500">
                      {{ formatarTamanhoArquivo(documento.file_size) }}
                    </p>
                    <p class="text-xs text-gray-400">
                      {{
                        documento.created_at
                          ? formatarData(documento.created_at)
                          : 'Documento anexado'
                      }}
                    </p>
                  </div>
                </div>
              </div>

              <div class="flex gap-2">
                <button
                  @click="visualizarArquivo(documento.file_url)"
                  class="flex-1 px-3 py-2 bg-abyss-primary text-white text-sm rounded font-semibold hover:bg-abyss-secondary transition flex items-center justify-center gap-1"
                >
                  <svg
                    class="w-4 h-4"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                    />
                  </svg>
                  Visualizar
                </button>
                <button
                  @click="baixarArquivo(documento.file_url, documento.filename)"
                  class="flex-1 px-3 py-2 bg-gray-200 text-abyss-dark text-sm rounded font-semibold hover:bg-gray-300 transition flex items-center justify-center gap-1"
                >
                  <svg
                    class="w-4 h-4"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                  Baixar
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-end mt-6">
          <button
            class="px-4 py-2 bg-abyss-primary text-abyss-black rounded font-bold shadow hover:bg-abyss-secondary transition"
            @click="fecharDetalhes"
          >
            Fechar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
