<template>
  <Layout>
    <div class="min-h-screen flex flex-col items-center px-8 py-8">
      <!-- Painéis de Gráficos -->
      <div class="w-full max-w-7xl grid grid-cols-1 md:grid-cols-2 gap-12 mb-12">
        <!-- Gráfico 1: Total de Processos por Força Responsável -->
        <div class="bg-white/10 backdrop-blur-md border border-white/20 rounded-lg shadow-xl p-8 flex flex-col min-h-[420px]">
          <div class="flex items-center gap-3 mb-4">
            <svg class="w-7 h-7 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
            </svg>
            <h2 class="text-xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">
              Processos por Força Responsável
            </h2>
          </div>
          <div v-if="dadosProcessosPorForca.length > 0" class="text-center mb-4">
            <div class="text-5xl font-bold text-white">{{ totalProcessosGrafico }}</div>
            <div class="text-sm text-slate-400">Total de Processos</div>
          </div>
          <div class="flex-1 w-full flex items-center justify-center">
            <BarChart
              v-if="dadosProcessosPorForca.length > 0 && !loading"
              :data="chartDataForca"
              :options="chartOptionsForca"
              class="w-full h-full"
            />
            <div v-else-if="loading" class="text-center">
              <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-teal-400"></div>
              <p class="text-slate-400 mt-2">Carregando...</p>
            </div>
            <div v-else class="text-center">
              <svg class="w-16 h-16 mx-auto text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path></svg>
              <p class="text-slate-400 mt-2">Nenhum processo para exibir.</p>
            </div>
          </div>
          <div class="flex items-center gap-3 mt-4">
            <button
              @click="exportToCSV(
                ['Forca_Responsavel', 'Total_Processos'],
                dadosProcessosPorForca.map(item => ({
                  'Forca_Responsavel': item.code,
                  'Total_Processos': item.total
                })),
                'processos_por_forca.csv'
              )"
              class="ml-auto px-3 py-1 text-xs bg-white/10 border border-teal-400 text-teal-400 rounded hover:bg-teal-400 hover:text-white transition"
            >Exportar (CSV)</button>
          </div>
        </div>
        <!-- Gráfico 2: Tempo Médio Gasto por Etapa -->
        <div class="bg-white/10 backdrop-blur-md border border-white/20 rounded-lg shadow-xl p-8 flex flex-col items-center min-h-[420px]">

    <div class="flex items-center gap-3 mb-4 self-start">
        <svg class="w-6 h-6 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <h2 class="text-xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">
            Análise de Tempo por Etapa
        </h2>
    </div>

    <div class="flex-1 w-full overflow-x-auto">
        <div :style="{ minWidth: chartWidthEtapa + 'px' }">
            <BarChart
                v-if="dadosTempoMedioEtapa.length"
                :data="chartDataEtapa"
                :options="chartOptionsEtapa"
                class="w-full"
                :height="320"
                :width="chartWidthEtapa"
            />
            <div v-else class="text-slate-400 text-center py-12">Carregando gráfico...</div>
        </div>
    </div>
    <div class="flex items-center gap-3 mt-4">
        <button
            @click="exportToCSV(
              ['Etapa', 'Media_Horas'],
              dadosTempoMedioEtapa.map(item => ({
                'Etapa': item.name,
                'Media_Horas': item.media_horas
              })),
              'tempo_medio_por_etapa.csv'
            )"
            class="ml-auto px-3 py-1 text-xs bg-white/10 border border-teal-400 text-teal-400 rounded hover:bg-teal-400 hover:text-white transition"
        >Exportar (CSV)</button>
    </div>
</div>
      </div>

      <!-- Linha do Tempo e Seletor -->
      <div class="w-full max-w-4xl bg-white/10 backdrop-blur-md border border-white/20 rounded-lg shadow-xl p-10">
        <h1 class="text-3xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent mb-4">Histórico</h1>
        <p class="text-slate-300 mb-6">Visualize a linha do tempo de todos os processos.</p>
        <!-- Seletor de Processo -->
        <div class="mb-8">
          <label class="block text-white font-semibold mb-2">Selecionar Processo</label>
          <select
            v-model="processoSelecionado"
            class="w-full md:w-96 px-4 py-2 rounded-lg bg-slate-900 text-white border border-teal-400 focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-teal-400 appearance-none"
            style="background-image: url('data:image/svg+xml;utf8,<svg fill=\'white\' height=\'20\' viewBox=\'0 0 20 20\' width=\'20\' xmlns=\'http://www.w3.org/2000/svg\'><path d=\'M7.293 7.293a1 1 0 011.414 0L10 8.586l1.293-1.293a1 1 0 111.414 1.414l-2 2a1 1 0 01-1.414 0l-2-2a1 1 0 010-1.414z\'/></svg>'); background-repeat: no-repeat; background-position: right 0.75rem center; background-size: 1.25em 1.25em;"
          >
            <option value="">Selecione um processo</option>
            <option v-for="processo in processos" :key="processo.id" :value="processo.id">
              {{ processo.nome_acao || 'Processo sem nome' }} - {{ processo.area_code || 'N/A' }}
            </option>
          </select>
        </div>

        <div v-if="loading" class="text-center py-12">
          <span class="text-lg font-semibold text-teal-400">Carregando histórico...</span>
        </div>

        <div v-else-if="processoSelecionado">
          <div class="mb-6 flex justify-center border-b border-white/20">
            <button
              @click="abaAtiva = 'etapas'"
              :class="[
                'px-6 py-2 text-lg font-semibold transition-colors duration-200',
                abaAtiva === 'etapas'
                  ? 'text-teal-300 border-b-2 border-teal-300'
                  : 'text-slate-400 hover:text-white'
              ]"
            >
              Etapas
            </button>
            <button
              @click="abaAtiva = 'alteracoes'"
              :class="[
                'px-6 py-2 text-lg font-semibold transition-colors duration-200',
                abaAtiva === 'alteracoes'
                  ? 'text-teal-300 border-b-2 border-teal-300'
                  : 'text-slate-400 hover:text-white'
              ]"
            >
              Alterações
            </button>
          </div>

          <div v-if="abaAtiva === 'etapas'">
            <div v-if="historicoEtapas.length > 0" class="space-y-6">
          <div class="relative">
            <div class="absolute left-6 top-0 bottom-0 w-0.5 bg-teal-400/50"></div>
            <div class="space-y-6">
                  <div v-for="evento in historicoEtapas" :key="evento.id" class="relative flex items-start">
                    <div class="absolute left-4 w-4 h-4 bg-cyan-400 rounded-full border-4 border-white shadow-lg z-10"></div>
                <div class="ml-12 bg-white/5 rounded-lg p-4 flex-1 shadow-sm">
                    <div class="flex items-start justify-between mb-2">
                      <h3 class="font-semibold text-white">{{ evento.description }}</h3>
                      <span class="text-sm text-slate-400">{{ formatarDataSimples(evento.changed_at) }}</span>
                    </div>
                    <div class="flex items-center gap-2 text-sm text-slate-300">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                      <span>{{ obterNomeUsuario(evento.profiles) }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="text-center py-12">
              <span class="text-lg font-semibold text-slate-400">Nenhum histórico de etapas encontrado.</span>
            </div>
          </div>

          <div v-if="abaAtiva === 'alteracoes'">
            <div v-if="historicoAlteracoes.length > 0" class="space-y-6">
              <div class="relative">
                <div class="absolute left-6 top-0 bottom-0 w-0.5 bg-teal-400/50"></div>
                <div class="space-y-6">
                  <div v-for="evento in historicoAlteracoes" :key="evento.id" class="relative flex items-start">
                    <div class="absolute left-4 w-4 h-4 bg-cyan-400 rounded-full border-4 border-white shadow-lg z-10"></div>
                    <div class="ml-12 bg-white/5 rounded-lg p-4 flex-1 shadow-sm">
                      <div class="flex items-start justify-between">
                        <p class="font-semibold text-white text-base leading-relaxed">
                          <span class="text-slate-300">{{ obterNomeUsuario(evento.user) }}</span> alterou <b>{{ formatarCampo(evento.field_name) }}</b> de
                          <span class="text-red-400 font-mono bg-black/20 px-1 rounded">'{{ formatarValor(evento.old_value, evento.field_name) }}'</span> para
                          <span class="text-green-400 font-mono bg-black/20 px-1 rounded">'{{ formatarValor(evento.new_value, evento.field_name) }}'</span>.
                        </p>
                        <span class="text-sm text-slate-400 flex-shrink-0 ml-4">{{ formatarDataSimples(evento.changed_at) }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="text-center py-12">
              <span class="text-lg font-semibold text-slate-400">Nenhum log de alterações encontrado.</span>
            </div>
          </div>
        </div>

        <div v-else class="text-center py-12">
          <span class="text-lg font-semibold text-slate-400">Selecione um processo para ver o histórico</span>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup lang="ts">
// IMPORTS
import Layout from '../components/Layout.vue'
import { ref, onMounted, watch, computed } from 'vue'
import { supabase } from '../services/supabase'
import { useAuth } from '../composables/useAuth'
import { useDashboardFilters } from '../composables/useDashboardFilters'
import { useRouter } from 'vue-router'
import { useFormatters } from '../composables/useFormatters'

// IMPORTAÇÃO DOS COMPONENTES DE GRÁFICO
import { Bar } from 'vue-chartjs'
import { Chart, BarElement, CategoryScale, LinearScale, Tooltip, Legend } from 'chart.js'
Chart.register(BarElement, CategoryScale, LinearScale, Tooltip, Legend)

// COMPONENTE DE GRÁFICO REUTILIZÁVEL
const BarChart = Bar

// Tipos auxiliares para tipagem dos dados
interface Processo {
  id: string
  nome_acao?: string
  area_code?: string
  thematic_areas?: { id: number; code: string } | { id: number; code: string }[]
}
interface EventoHistorico {
  id: string
  process_id: string
  user_id: string
  changed_at: string
  description: string
  profiles?: { nome?: string }
  type?: 'history'
}
interface EventoAudit {
  id: string
  process_id: string
  user_id: string | null
  changed_at: string
  field_name: string
  old_value: string | null
  new_value: string | null
  user?: { nome?: string }
  type?: 'audit'
}

// Novo tipo para força
interface Forca {
  id: number
  code: string
  name: string
}
// Novo tipo para etapa
interface Etapa {
  id: number
  name: string
}

// Remover interfaces não utilizadas

// --- DADOS E ESTADOS REATIVOS ---
const { user, fetchUser } = useAuth()
const processos = ref<Processo[]>([])
const processoSelecionado = ref('')
const loading = ref(false)

// NOVO: Estado para controlar a aba ativa
const abaAtiva = ref<'etapas' | 'alteracoes'>('etapas')

// NOVO: Arrays de histórico separados
const historicoEtapas = ref<EventoHistorico[]>([])
const historicoAlteracoes = ref<EventoAudit[]>([])

// Dados dos gráficos
const dadosProcessosPorForca = ref<Array<{ code: string; total: number }>>([])
const dadosTempoMedioEtapa = ref<Array<{ name: string; media_horas: number }>>([])
const totalProcessosGrafico = computed(() => dadosProcessosPorForca.value.reduce((acc, f) => acc + f.total, 0))

// Propriedade computada para largura dinâmica do gráfico de etapas (barras verticais)
const chartWidthEtapa = computed(() => {
  const itemsCount = dadosTempoMedioEtapa.value.length
  if (itemsCount === 0) return 600
  // 80px por etapa, mínimo 600px
  return Math.max(itemsCount * 80, 600)
})

// --- FUNÇÕES DE BUSCA PARA OS GRÁFICOS ---

const router = useRouter()
const { setFiltroForca } = useDashboardFilters()

// Array de forças para mapear code -> id
const forcasMem = ref<Forca[]>([])

// Atualizar forcasMem ao buscar forças
async function fetchForcas() {
  const { data } = await supabase
    .from('responsible_forces')
    .select('id, code, name')
    .order('code', { ascending: true })
  forcasMem.value = (data as Forca[]) || []
  return forcasMem.value
}

// Busca todas as etapas cadastradas
async function fetchEtapas() {
  const { data } = await supabase
    .from('step_templates')
    .select('id, name')
    .order('id', { ascending: true })
  return (data as Etapa[]) || []
}

// Corrigida: conta processos por code da força e mostra todas as forças
async function fetchProcessosPorForca() {
  const forcas = await fetchForcas()
  const { data, error } = await supabase
    .from('processes')
    .select('responsible_force_id')
    .not('responsible_force_id', 'is', null)
    .is('deleted_at', null)
  // Conta por id
  const contagem: Record<number, number> = {}
  if (data) {
    for (const proc of data) {
      const id = proc.responsible_force_id
      if (!contagem[id]) contagem[id] = 0
      contagem[id]++
    }
  }
  // Garante que todas as forças aparecem, mesmo com zero
  dadosProcessosPorForca.value = forcas.map((f) => ({
    code: f.code,
    total: contagem[f.id] || 0,
  }))
  // Log para depuração
  console.log('Forças:', forcas)
  console.log('Processos:', data, error)
  console.log('Contagem:', contagem)
  console.log('dadosProcessosPorForca:', dadosProcessosPorForca.value)
}

// Corrigida: mostra todas as etapas cadastradas, mesmo com média zero
async function fetchTempoMedioPorEtapa() {
  const etapas = await fetchEtapas()
  const { data } = await supabase
    .from('process_steps')
    .select('step_template_id, started_at, ended_at, accumulated_duration_seconds, processes(deleted_at)')
    .not('ended_at', 'is', null)
    .not('started_at', 'is', null)
  // Não filtra por processos excluídos, considera todas as etapas
  const etapasAtivas = data;
  // LOGS DE DEPURAÇÃO
  console.log('Etapas cadastradas:', etapas);
  console.log('Etapas ativas para o gráfico:', etapasAtivas);
  // Agrupa por etapa e calcula média
  const grupos: Record<number, { total: number; soma: number }> = {}
  if (etapasAtivas) {
    for (const step of etapasAtivas) {
      const diffHoras = step.accumulated_duration_seconds !== undefined && step.accumulated_duration_seconds !== null
        ? Math.abs(step.accumulated_duration_seconds) / (60 * 60)
        : Math.abs(new Date(step.ended_at).getTime() - new Date(step.started_at).getTime()) / (1000 * 60 * 60)
      const id = step.step_template_id
      if (!grupos[id]) grupos[id] = { total: 0, soma: 0 }
      grupos[id].total++
      grupos[id].soma += diffHoras
    }
  }
  console.log('Grupos calculados:', grupos);
  // Garante que todas as etapas aparecem, mesmo com média zero
  dadosTempoMedioEtapa.value = etapas.map((e) => ({
    name: e.name,
    media_horas: grupos[e.id]?.total
      ? Number((grupos[e.id].soma / grupos[e.id].total).toFixed(2))
      : 0,
  }))
  console.log('Dados finais do gráfico:', dadosTempoMedioEtapa.value);
}

// --- CHART DATA/OPTIONS PARA OS GRÁFICOS ---

// Gráfico de barras de processos por força (usando code)
const chartDataForca = computed(() => ({
  labels: dadosProcessosPorForca.value.map((f) => f.code),
  datasets: [
    {
      label: 'Total de Processos',
      data: dadosProcessosPorForca.value.map((f) => f.total),
      backgroundColor: '#2dd4bf', // teal-400 vibrante
      borderRadius: 8,
    },
  ],
}))
const chartOptionsForca = {
  responsive: true,
  plugins: {
    legend: { display: false },
    tooltip: {
      enabled: true,
      backgroundColor: 'rgba(0,0,0,0.7)',
      titleColor: '#fff',
      bodyColor: '#fff',
    },
    title: { color: '#fff' },
  },
  scales: {
    y: {
      beginAtZero: true,
      ticks: { color: '#9ca3af', font: { weight: 'bold' as const } }, // slate-400
      grid: { color: 'rgba(255,255,255,0.1)' },
    },
    x: {
      ticks: { color: '#9ca3af', font: { weight: 'bold' as const } },
      grid: { color: 'rgba(255,255,255,0.05)' },
    },
  },
  onClick: (event, elements, chart) => {
    if (!elements.length) return
    const idx = elements[0].index
    const code = chart.data.labels[idx]
    const forca = forcasMem.value.find(f => f.code === code)
    if (forca) {
      setFiltroForca(forca.id)
      router.push('/')
    }
  },
}

// Gráfico de barras horizontais de tempo médio por etapa
const chartDataEtapa = computed(() => ({
  labels: dadosTempoMedioEtapa.value.map((e) => e.name),
  datasets: [
    {
      label: 'Média (horas)',
      data: dadosTempoMedioEtapa.value.map((e) => e.media_horas),
      backgroundColor: '#14b8a6',
      borderRadius: 8,
    },
  ],
}))
const chartOptionsEtapa = {
  responsive: true,
  plugins: {
    legend: { display: false },
    tooltip: {
      enabled: true,
      backgroundColor: 'rgba(0,0,0,0.7)',
      titleColor: '#fff',
      bodyColor: '#fff',
    },
    title: { color: '#fff' },
  },
  scales: {
    y: {
      beginAtZero: true,
      ticks: { color: '#9ca3af', font: { weight: 'bold' as const } },
      grid: { color: 'rgba(255,255,255,0.1)' },
    },
    x: {
      ticks: { color: '#9ca3af', font: { weight: 'bold' as const } },
      grid: { color: 'rgba(255,255,255,0.05)' },
    },
  },
}

// --- LINHA DO TEMPO (JÁ EXISTENTE) ---

// ATUALIZADO: Função para buscar os dois tipos de histórico
async function buscarHistorico(id: string) {
  console.log('Buscando histórico para processoSelecionado:', id);
  if (!id) {
    historicoEtapas.value = [];
    historicoAlteracoes.value = [];
    return;
  }
  loading.value = true;
  // Reseta os arrays e a aba
  historicoEtapas.value = [];
  historicoAlteracoes.value = [];
  abaAtiva.value = 'etapas'; // Volta para a aba padrão

  // 1. Busca o histórico de etapas (process_history)
  const { data: historyData } = await supabase
    .from('process_history')
    .select('*, profiles(id, nome)')
    .eq('process_id', id)
    .order('changed_at', { ascending: false });

  if (historyData) {
    historicoEtapas.value = historyData;
  }

  // 2. Busca o log de auditoria (audit_log)
  //    Busca sem join, depois busca nomes manualmente
  const { data: auditData } = await supabase
    .from('audit_log')
    .select('*')
    .eq('process_id', id)
    .order('changed_at', { ascending: false });

  if (auditData && auditData.length > 0) {
    // Buscar todos os user_ids únicos (compatível com targets antigos)
    const userIds = auditData
      .map(item => item.user_id)
      .filter((id, idx, arr) => id && arr.indexOf(id) === idx);
    let userMap = {};
    if (userIds.length > 0) {
      const { data: users } = await supabase
        .from('profiles')
        .select('id, nome')
        .in('id', userIds);
      if (users) {
        userMap = Object.fromEntries(users.map(u => [u.id, u.nome]));
      }
    }
    // Adicionar o nome ao log
    historicoAlteracoes.value = auditData.map(item => ({
    ...item,
      user: { nome: userMap[item.user_id] || 'Usuário desconhecido' }
    }));
  } else {
    historicoAlteracoes.value = [];
  }

  console.log('Histórico de Etapas:', historicoEtapas.value);
  console.log('Histórico de Alterações:', historicoAlteracoes.value);
  loading.value = false;
}
// --- NOVOS TRADUTORES PARA O HISTÓRICO ---

// 1. Mapeia nomes técnicos dos campos para nomes amigáveis
const nomesAmigaveisCampos: Record<string, string> = {
  deleted_at: 'Status do Processo', // ou 'Data de Exclusão' se preferir
  descricao_itens: 'Descrição dos Itens',
  nome_acao: 'Nome da Ação',
  valor_total_destinado: 'Valor Total Destinado',
  // Adicione outros campos da tabela 'processes' aqui conforme precisar
};

// 2. Função que traduz o nome do campo
function formatarCampo(fieldName: string): string {
  return nomesAmigaveisCampos[fieldName] || fieldName;
}

// 3. Função que traduz o valor, com lógica especial para o 'deleted_at'
function formatarValor(value: string | null, fieldName: string): string {
  const isNullish = value === null || value === 'NULL' || value === '';

  // Lógica específica para o campo 'deleted_at'
  if (fieldName === 'deleted_at') {
    // Se o valor for nulo, significa que o processo está ATIVO.
    // Se tiver uma data, significa que foi EXCLUÍDO.
    return isNullish ? 'Ativo' : 'Excluído';
  }

  // Lógica padrão para outros campos
  return isNullish ? 'vazio' : value;
}

// WATCH: Observa mudanças no processoSelecionado
watch(processoSelecionado, (novoId) => {
  if (novoId) {
    buscarHistorico(novoId);
  } else {
    historicoEtapas.value = [];
    historicoAlteracoes.value = [];
  }
})

// Adiciona um event listener global para refresh
if (typeof window !== 'undefined') {
  window.addEventListener('refresh-historico', () => {
    if (processoSelecionado.value) {
      buscarHistorico(processoSelecionado.value)
    }
  })
}

// Carrega a lista de processos e os gráficos ao montar o componente
onMounted(async () => {
  let usuario = user.value
  if (!usuario) {
    usuario = await fetchUser()
  }
  if (!usuario) {
    processos.value = []
    return
  }
  // Carrega processos para o dropdown
  const { data } = await supabase
    .from('processes')
    .select('id, nome_acao, thematic_areas(id, code)')
    .is('deleted_at', null)
    .order('created_at', { ascending: false })
  if (data) {
    processos.value = (data as Processo[]).map((proc) => {
      let area_code = ''
      if (Array.isArray(proc.thematic_areas) && proc.thematic_areas.length > 0) {
        area_code = proc.thematic_areas[0].code
      } else if (proc.thematic_areas && typeof proc.thematic_areas === 'object') {
        area_code = (proc.thematic_areas as { code: string }).code
      }
      return {
        id: proc.id,
        nome_acao: proc.nome_acao,
        area_code,
      }
    })
  }
  // Carrega os dados dos gráficos
  await fetchProcessosPorForca()
  await fetchTempoMedioPorEtapa()
  await fetchForcas() // popula forcasMem
})

// Importar funções de formatação do composable
const { formatarData: formatarDataSimples } = useFormatters()
// Usar formatarDataSimples para datas sem hora

// Formata a data/hora para exibição amigável com hora e minuto (específica para análises)


// ATUALIZADO: Função para obter nome do usuário (mais robusta)
function obterNomeUsuario(profileOrId: { nome?: string } | string | null | undefined) {
  if (typeof profileOrId === 'string') return profileOrId || 'Usuário desconhecido';
  return profileOrId?.nome || 'Usuário desconhecido';
}

// [FUNÇÃO UTILITÁRIA DE EXPORTAÇÃO CSV]
function exportToCSV(headers: string[], rows: Array<Record<string, unknown>>, filename: string) {
  if (!rows || rows.length === 0) return;
  // Cabeçalho
  const headerLine = headers.join(',');
  // Linhas de dados
  const dataLines = rows.map(row =>
    headers.map(h => {
      let val = row[h] !== undefined && row[h] !== null ? String(row[h]) : '';
      if (val.includes(',') || val.includes('"')) {
        val = '"' + val.replace(/"/g, '""') + '"';
      }
      return val;
    }).join(',')
  );
  const csvContent = [headerLine, ...dataLines].join('\n');
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
</script>
