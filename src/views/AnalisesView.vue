<template>
  <Layout>
    <div class="min-h-screen w-full flex flex-col items-center px-8 py-8">

      <div class="w-full max-w-7xl mb-12">
        <div class="flex flex-col md:flex-row justify-between items-center gap-4">
          <h1 class="text-3xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">
            Painel de Análises
          </h1>


          <div class="w-full max-w-7xl mb-12">
  <div class="flex flex-col md:flex-row justify-between items-center gap-4">
    <h1 class="text-3xl ...">

    </h1>

        <div class="flex items-center gap-4">
           <div class="flex flex-col">
              <label class="text-xs text-slate-400 mb-1 text-center">Filtrar por Ano</label>
                <select
                  v-model="filtroAno"
                  class="px-3 py-2 rounded-lg bg-slate-800/80 text-white border border-white/10 focus:outline-none focus:ring-2 focus:ring-teal-400 appearance-none text-sm"
                  style="background-image: url('...');">
                  <option value="">Todos os Anos</option>
                  <option v-for="ano in anos" :key="ano" :value="ano">{{ ano }}</option>
                 </select>
               </div>

               <div class="flex bg-slate-800/80 rounded-lg p-1.5 ...">
             </div>
            </div>
           </div>
          </div>
          <div class="flex bg-slate-800/80 rounded-lg p-1.5 backdrop-blur-sm border border-white/10">
            <button
                @click="painelAtivo = 'processos'"
                :class="[
                    'px-5 py-2 text-sm font-semibold rounded-md transition-all duration-300',
                    painelAtivo === 'processos'
                        ? 'bg-gradient-to-r from-teal-600 to-cyan-500 text-white shadow-md'
                        : 'text-slate-300 hover:bg-white/5'
                ]"
            >
                Análise de Processos
            </button>
            <button
                @click="painelAtivo = 'financeiro'"
                :class="[
                    'px-5 py-2 text-sm font-semibold rounded-md transition-all duration-300',
                    painelAtivo === 'financeiro'
                        ? 'bg-gradient-to-r from-teal-600 to-cyan-500 text-white shadow-md'
                        : 'text-slate-300 hover:bg-white/5'
                ]"
            >
                Análise Financeira
            </button>
          </div>
        </div>
      </div>

      <div v-if="painelAtivo === 'processos'" class="w-full max-w-7xl mx-auto space-y-12">
        <div class="grid grid-cols-1 md:grid-cols-1 gap-12">
          <div class="bg-white/10 backdrop-blur-md border border-white/20 rounded-lg shadow-xl p-8 flex flex-col max-h-[500px] overflow-y-auto">
            <div class="flex items-center gap-3 mb-4 self-start">
              <svg class="w-6 h-6 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              <h2 class="text-xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">Análise de Tempo por Etapa</h2>
            </div>
            <div class="flex-1 w-full overflow-x-auto">
              <div :style="{ height: chartHeightEtapa + 'px', minWidth: '500px'}">
                <BarChart v-if="dadosTempoMedioEtapa.length" :data="chartDataEtapa" :options="chartOptionsEtapa" class="w-full" :height="320" :width="chartHeightEtapa" />
                <div v-else class="text-slate-400 text-center py-12">Carregando gráfico...</div>
              </div>
            </div>
            <div class="flex items-center gap-3 mt-4">
              <button @click="exportToCSV(['Etapa', 'Media_Horas'], dadosTempoMedioEtapa.map(item => ({ 'Etapa': item.name, 'Media_Horas': item.media_horas })), 'tempo_medio_por_etapa.csv')" class="ml-auto px-3 py-1 text-xs bg-white/10 border border-teal-400 text-teal-400 rounded hover:bg-teal-400 hover:text-white transition">Exportar (CSV)</button>
            </div>
          </div>
        </div>
        <div class="w-full bg-white/10 backdrop-blur-md border border-white/20 rounded-lg shadow-xl p-8">
          <h1 class="text-3xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent mb-4">Histórico</h1>
          <p class="text-slate-300 mb-6">Visualize a linha do tempo de todos os processos.</p>
          <div class="mb-8 w-full md:w-96">
            <label class="block text-white font-semibold mb-2">Buscar Processo por Nome ou SEI</label>
              <Combobox v-model="processoSelecionado">
                <div class="relative">
                  <div class="relative w-full cursor-default overflow-hidden rounded-lg bg-slate-900 text-left border border-teal-400 focus-within:ring-2 focus-within:ring-white/75 sm:text-sm">
  <ComboboxInput
    class="w-full border-none bg-transparent py-2 pl-3 pr-10 text-sm leading-5 text-white focus:ring-0 h-10"
    :displayValue="(id) => processos.find(p => p.id === id)?.nome_acao || ''"
    @change="queryHistorico = $event.target.value"
  />

  <button
    v-if="processoSelecionado"
    @click="limparSelecaoHistorico"
    class="absolute inset-y-0 right-10 flex items-center pr-2"
    title="Limpar seleção"
  >
    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-red-400 hover:text-white" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
    </svg>
  </button>
  
  <ComboboxButton class="absolute inset-y-0 right-0 flex items-center pr-2">
    <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 3a1 1 0 01.707.293l3 3a1 1 0 01-1.414 1.414L10 5.414 7.707 7.707a1 1 0 01-1.414-1.414l3-3A1 1 0 0110 3zm-3.707 9.293a1 1 0 011.414 0L10 14.586l2.293-2.293a1 1 0 011.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" /></svg>
  </ComboboxButton>
</div>
                <transition leave-active-class="transition duration-100 ease-in" leave-from-class="opacity-100" leave-to-class="opacity-0">
                <ComboboxOptions class="absolute mt-1 max-h-60 w-full overflow-auto rounded-md bg-slate-800 py-1 text-base shadow-lg ring-1 ring-black/5 focus:outline-none sm:text-sm z-10">
              <div v-if="processosFiltrados.length === 0 && queryHistorico !== ''" class="relative cursor-default select-none py-2 px-4 text-gray-400">
                Nenhum processo encontrado.
              </div>
                <ComboboxOption
                  v-for="processo in processosFiltrados"
                  :key="processo.id"
                  :value="processo.id"
                  v-slot="{ selected, active }"
                  >
                    <li :class="{ 'bg-teal-600 text-white': active, 'text-slate-200': !active }" class="relative cursor-default select-none py-2 pl-4 pr-4">
                      <span :class="{ 'font-medium': selected, 'font-normal': !selected }" class="block">
                        {{ processo.nome_acao || 'Processo sem nome' }}
                        <span class="text-xs text-slate-400 block">{{ processo.codigo_transferegov || 'Sem SEI' }}</span>
                      </span>
                    </li>
                  </ComboboxOption>
                </ComboboxOptions>
              </transition>
            </div>
          </Combobox>
        </div>
        <div v-if="loading" class="text-center py-12"><span class="text-lg font-semibold text-teal-400">Carregando histórico...</span></div>
        <div v-else-if="processoSelecionado">
            <div class="mb-6 flex justify-center border-b border-white/20">
              <button @click="abaAtiva = 'etapas'" :class="['px-6 py-2 text-lg font-semibold transition-colors duration-200', abaAtiva === 'etapas' ? 'text-teal-300 border-b-2 border-teal-300' : 'text-slate-400 hover:text-white']">Etapas</button>
              <button @click="abaAtiva = 'alteracoes'" :class="['px-6 py-2 text-lg font-semibold transition-colors duration-200', abaAtiva === 'alteracoes' ? 'text-teal-300 border-b-2 border-teal-300' : 'text-slate-400 hover:text-white']">Alterações</button>
            </div>
            <div v-if="abaAtiva === 'etapas'" class="max-h-[400px] overflow-y-auto pr-4">
              <div v-if="historicoEtapas.length > 0" class="space-y-6">
                <div class="relative"><div class="absolute left-6 top-0 bottom-0 w-0.5 bg-teal-400/50"></div>
                  <div class="space-y-6">
                    <div v-for="evento in historicoEtapas" :key="evento.id" class="relative flex items-start"><div class="absolute left-4 w-4 h-4 bg-cyan-400 rounded-full border-4 border-white shadow-lg z-10"></div>
                      <div class="ml-12 bg-white/5 rounded-lg p-4 flex-1 shadow-sm">
                        <div class="flex items-start justify-between mb-2"><h3 class="font-semibold text-white">{{ evento.description }}</h3><span class="text-sm text-slate-400">{{ formatarDataSimples(evento.changed_at) }}</span></div>
                        <div class="flex items-center gap-2 text-sm text-slate-300"><svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg><span>{{ obterNomeUsuario(evento.profiles) }}</span></div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div v-else class="text-center py-12"><span class="text-lg font-semibold text-slate-400">Nenhum histórico de etapas encontrado.</span></div>
            </div>
            <div v-if="abaAtiva === 'alteracoes'" class="max-h-[400px] overflow-y-auto pr-4">
              <div v-if="historicoAlteracoes.length > 0" class="space-y-6">
                <div class="relative"><div class="absolute left-6 top-0 bottom-0 w-0.5 bg-teal-400/50"></div>
                  <div class="space-y-6">
                    <div v-for="evento in historicoAlteracoes" :key="evento.id" class="relative flex items-start"><div class="absolute left-4 w-4 h-4 bg-cyan-400 rounded-full border-4 border-white shadow-lg z-10"></div>
                      <div class="ml-12 bg-white/5 rounded-lg p-4 flex-1 shadow-sm">
                        <div class="flex items-start justify-between">
                          <p class="font-semibold text-white text-base leading-relaxed"><span class="text-slate-300">{{ obterNomeUsuario(evento.user) }}</span> alterou <b>{{ formatarCampo(evento.field_name) }}</b> de <span class="text-red-400 font-mono bg-black/20 px-1 rounded">'{{ formatarValor(evento.old_value, evento.field_name) }}'</span> para <span class="text-green-400 font-mono bg-black/20 px-1 rounded">'{{ formatarValor(evento.new_value, evento.field_name) }}'</span>.</p>
                          <span class="text-sm text-slate-400 flex-shrink-0 ml-4">{{ formatarDataSimples(evento.changed_at) }}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div v-else class="text-center py-12"><span class="text-lg font-semibold text-slate-400">Nenhum log de alterações encontrado.</span></div>
            </div>
          </div>
          <div v-else class="text-center py-12"><span class="text-lg font-semibold text-slate-400">Selecione um processo para ver o histórico</span></div>
        </div>
      </div>

      <div v-else-if="painelAtivo === 'financeiro'" class="w-full max-w-7xl space-y-8">

  <div class="grid grid-cols-1 sm:grid-cols-2 gap-8">
    <div class="bg-slate-800/50 backdrop-blur-md border border-white/10 rounded-xl shadow-xl p-6 flex items-center gap-6">
      <div class="flex-shrink-0 w-16 h-16 bg-gradient-to-br from-teal-500 to-cyan-500 rounded-lg flex items-center justify-center">
        <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>
      </div>
      <div>
        <h2 class="text-lg font-semibold text-teal-300">Total em Projetos</h2>
        <div class="text-3xl font-bold text-white tracking-tight">{{ formatarMoeda(totalProjetos) }}</div>
      </div>
    </div>

    <div class="bg-slate-800/50 backdrop-blur-md border border-white/10 rounded-xl shadow-xl p-6 flex items-center gap-6">
       <div class="flex-shrink-0 w-16 h-16 bg-gradient-to-br from-cyan-500 to-blue-500 rounded-lg flex items-center justify-center">
        <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>
      </div>
      <div>
        <h2 class="text-lg font-semibold text-cyan-300">Economicidade</h2>
        <div class="text-3xl font-bold text-white tracking-tight">{{ formatarMoeda(totalEconomicidade) }}</div>
      </div>
    </div>
  </div>

  <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
    <div class="lg:col-span-2 bg-white/10 backdrop-blur-md border border-white/20 rounded-lg shadow-xl p-8 flex flex-col min-h-[500px]">
      <h2 class="text-xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent mb-4">
        Comparativo de Valor por Órgão
      </h2>
      <div class="flex-1 w-full">
        <BarChart v-if="dadosValoresPorOrgao.length && !loading" :data="chartDataValores" :options="chartOptionsValores" />
        <div v-else class="text-slate-400 text-center pt-24">Carregando dados financeiros...</div>
      </div>
    </div>

    <div class="lg:col-span-1 flex flex-col gap-8">
      <div class="bg-white/10 backdrop-blur-md border border-white/20 rounded-lg shadow-xl p-6 flex flex-col min-h-[350px]">
         <h2 class="text-lg font-bold text-slate-200 mb-4 text-center">Ranking de Pagamento</h2>
         <div class="flex-1 w-full">
           <BarChart v-if="dadosRankingPagamento.length" :data="chartDataRankingPagamento" :options="chartOptionsRankingPagamento" />
           <div v-else class="text-slate-400 text-center pt-16">Calculando ranking...</div>
         </div>
      </div>
      <div class="bg-white/10 backdrop-blur-md border border-white/20 rounded-lg shadow-xl p-6 flex flex-col min-h-[350px]">
         <h2 class="text-lg font-bold text-slate-200 mb-4 text-center">Qtd. de Processos por Órgão</h2>
         <div class="flex-1 w-full">
           <BarChart v-if="dadosProcessosPorForca.length" :data="chartDataQuantidadeProcessos" :options="chartOptionsQuantidadeProcessos" />
           <div v-else class="text-slate-400 text-center pt-16">Carregando...</div>
         </div>
      </div>
    </div>
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
import { Listbox, ListboxButton, ListboxOptions, ListboxOption } from '@headlessui/vue'
import { Combobox, ComboboxInput, ComboboxButton, ComboboxOptions, ComboboxOption } from '@headlessui/vue'
// IMPORTAÇÃO DOS COMPONENTES DE GRÁFICO
import { Bar } from 'vue-chartjs'
import { Chart, BarElement, CategoryScale, LinearScale, Tooltip, Legend } from 'chart.js'
import ChartDataLabels from 'chartjs-plugin-datalabels';
Chart.register(BarElement, CategoryScale, LinearScale, Tooltip, Legend, ChartDataLabels)

// COMPONENTE DE GRÁFICO REUTILIZÁVEL
const BarChart = Bar

// Tipos auxiliares para tipagem dos dados
interface Processo {
  id: string
  nome_acao?: string
  area_code?: string
  codigo_transferegov?: string
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
const painelAtivo = ref<'processos' | 'financeiro'>('processos')
const filtroAno = ref<number | string>('')
const anos = computed(() => {
  const anoAtual = new Date().getFullYear();
  const lista = []
  for (let ano = 2019; ano <= anoAtual; ano++) {
    lista.push(ano);
  }
  return lista.reverse();
});

// NOVO: Estado para controlar a aba ativa
const abaAtiva = ref<'etapas' | 'alteracoes'>('etapas')

// NOVO: Arrays de histórico separados
const historicoEtapas = ref<EventoHistorico[]>([])
const historicoAlteracoes = ref<EventoAudit[]>([])

// Dados dos gráficos
const dadosProcessosPorForca = ref<Array<{ code: string; total: number }>>([])
const dadosTempoMedioEtapa = ref<Array<{ name: string; media_horas: number }>>([])
const totalProcessosGrafico = computed(() => dadosProcessosPorForca.value.reduce((acc, f) => acc + f.total, 0))
const dadosValoresPorOrgao = ref<Array<{ id: number; code: string; valor_total: number}>>([])
const { formatarData: formatarDataSimples, formatarValor: formatarMoeda } = useFormatters()
const dadosGastosPorOrgao = ref<Array<{ id: number; code: string; total_gasto: number}>>([]);

const totalProjetos = ref(0);
const totalEconomicidade = ref(0);

// Propriedade computada para largura dinâmica do gráfico de etapas (barras verticais)
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
  // ✨ CORREÇÃO: Converte o ano para número antes de enviar
  const anoSelecionado = filtroAno.value;
  const p_ano = anoSelecionado ? parseInt(String(anoSelecionado), 10) : null;

  const forcas = forcasMem.value.length ? forcasMem.value : await fetchForcas();
  const { data } = await supabase.rpc('get_processos_por_forca', { p_ano });

  const contagem: Record<number, number> = {};
  if (data) {
    for (const proc of data) {
      const id = proc.responsible_force_id;
      if (!contagem[id]) contagem[id] = 0;
      contagem[id]++;
    }
  }
  dadosProcessosPorForca.value = forcas.map((f) => ({
    code: f.code,
    total: contagem[f.id] || 0,
  }));
}

// Em AnalisesView.vue -> <script setup>

async function fetchTempoMedioPorEtapa() {
  const anoSelecionado = filtroAno.value;
  const p_ano = anoSelecionado ? parseInt(String(anoSelecionado), 10) : null;

  const etapas = await fetchEtapas(); // Busca os nomes de todas as etapas possíveis
  const { data, error } = await supabase.rpc('get_dados_tempo_etapa', { p_ano });

  if (error) {
    console.error('Erro ao buscar dados de tempo por etapa:', error);
    dadosTempoMedioEtapa.value = []; // Zera os dados em caso de erro
    return;
  }

  const grupos: Record<number, { total: number; soma: number }> = {};
  if (data) {
    for (const step of data) {
      // Calcula a duração em horas para cada etapa retornada
      const diffHoras = step.accumulated_duration_seconds != null
        ? Math.abs(step.accumulated_duration_seconds) / 3600
        : Math.abs(new Date(step.ended_at).getTime() - new Date(step.started_at).getTime()) / 3600000;

      const id = step.step_template_id;
      if (!grupos[id]) grupos[id] = { total: 0, soma: 0 };
      grupos[id].total++;
      grupos[id].soma += diffHoras;
    }
  }

  // Mapeia os resultados para garantir que todas as etapas apareçam no gráfico
  dadosTempoMedioEtapa.value = etapas.map((e) => ({
    name: e.name,
    media_horas: grupos[e.id]?.total
      ? Number((grupos[e.id].soma / grupos[e.id].total).toFixed(2))
      : 0,
  }));
}


async function fetchValoresPorOrgao() {
  // ✨ CORREÇÃO: Converte o ano para número antes de enviar
  const anoSelecionado = filtroAno.value;
  const p_ano = anoSelecionado ? parseInt(String(anoSelecionado), 10) : null;

  const { data, error } = await supabase.rpc('get_valores_por_orgao', { p_ano });
  if (error) { console.error('Erro ao buscar valores por órgão:', error); dadosValoresPorOrgao.value = []; return; }
  dadosValoresPorOrgao.value = data || [];
}

async function fetchGastosPorOrgao() {

  const anoSelecionado = filtroAno.value;
  const p_ano = anoSelecionado ? parseInt(String(anoSelecionado), 10) : null;

  const { data, error} = await supabase.rpc('get_gastos_por_orgao', { p_ano });
  if (error) { console.error('Erro ao buscar gastos por órgão:', error); dadosGastosPorOrgao.value = []; return; }
  dadosGastosPorOrgao.value = data || [];
}

async function fetchTotaisFinanceiros() {
  const anoSelecionado = filtroAno.value;
  const p_ano = anoSelecionado ? parseInt(String(anoSelecionado), 10) : null;

  try {
    // ✨ NOVO: Busca a economicidade total a partir da nova função RPC
    const { data: economicidadeData, error: economicidadeError } = await supabase.rpc('get_total_economicidade', { p_ano });
    
    // Antigo RPC para o total de projetos (mantido para o outro card)
    const { data: projetosData, error: projetosError } = await supabase.rpc('get_totais_financeiros', { p_ano });

    if (economicidadeError) {
      console.error('Erro ao buscar economicidade total:', economicidadeError);
      totalEconomicidade.value = 0;
    } else {
      totalEconomicidade.value = economicidadeData || 0;
    }

    if (projetosError) {
      console.error('Erro ao buscar total de projetos:', projetosError);
      totalProjetos.value = 0;
    } else {
      if (projetosData && projetosData.length > 0) {
        totalProjetos.value = projetosData[0].total_projetos || 0;
      }
    }
  } catch (error) {
    console.error('Erro geral ao buscar totais financeiros:', error);
    totalProjetos.value = 0;
    totalEconomicidade.value = 0;
  }
}

async function carregarDadosDosGraficos() {
  loading.value = true;
  await Promise.all([
    fetchProcessosPorForca(),
    fetchTempoMedioPorEtapa(),
    fetchValoresPorOrgao(),
    fetchGastosPorOrgao(),
    fetchTotaisFinanceiros(),
  ]);
  loading.value = false;
}

watch(filtroAno, () => {
  carregarDadosDosGraficos();
})

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
  maintainAspectRatio: false, // Adicionado para consistência
  plugins: {
    legend: { display: false },
    tooltip: {
      enabled: true,
      backgroundColor: 'rgba(0,0,0,0.7)',
      titleColor: '#fff',
      bodyColor: '#fff',
    },
  },
  scales: {
    y: {
      beginAtZero: true,
      ticks: { color: '#cbd5e1', font: { weight: 'bold' as const } },
      grid: { color: 'rgba(255,255,255,0.1)' },
    },
    x: {
      ticks: { color: '#cbd5e1', font: { weight: 'bold' as const } },
      grid: { color: 'rgba(255,255,255,0.05)' },
    },
  },
  onClick: (event, elements, chart) => {
    if (!elements.length) return;
    const idx = elements[0].index;
    const code = chart.data.labels?.[idx] as string;
    if (code) {
      const forca = forcasMem.value.find(f => f.code === code);
    if (forca) {
        setFiltroForca(forca.id);
        router.push('/');
      }
    }
  },
};

// Gráfico de barras horizontais de tempo médio por etapa

const chartDataEtapa = computed(() => ({
  labels: dadosTempoMedioEtapa.value.map((e) => e.name),
  datasets: [
    {
      label: 'Média (horas)',
      data: dadosTempoMedioEtapa.value.map((e) => e.media_horas),

      backgroundColor: dadosTempoMedioEtapa.value.map((_, index) =>
    index % 2 === 0 ? '#4ade80' : '#22d3ee'
  ),
    borderRadius: 6,
    },
  ],
}));

// SUBSTITUA TODO O SEU 'chartOptionsEtapa' POR ESTE

const chartOptionsEtapa = {
  indexAxis: 'y' as const,
  responsive: true,
  maintainAspectRatio: false,
  datasets: { // <-- NOVO: Adicionado para controlar a espessura
    bar: {
      barPercentage: 0.7, // A barra ocupa 70% do espaço disponível
      categoryPercentage: 0.8, // O grupo de barras ocupa 80% da categoria
    }
  },
  plugins: {
    legend: { display: false },
    tooltip: {
      enabled: true,
      backgroundColor: 'rgba(0,0,0,0.7)',
      titleColor: '#fff',
      bodyColor: '#fff',
      callbacks: {
        // CORRIGIDO: Garante que a função seja executada
        label: (context) => {
          let label = context.dataset.label || '';
          if (label) {
            label += ': ';
          }
          if (context.parsed.x !== null) {
            label += context.parsed.x.toFixed(2) + ' horas';
          }
          return label;
        }
      }
    },
    datalabels: {
      color: '#ffffff',
      anchor: 'end' as const,
      align: 'end' as const,
      offset: 8, // Offset positivo para colocar o texto fora da barra
      font: {
        weight: 'bold' as const,
        size: 12,
      },
      // CORRIGIDO: Garante que a função formatter seja executada
      formatter: (value, context) => {
        if (value > 0) {
          return `${Number(value).toFixed(2)}h`;
        }
        return '';
      }
    }
  },
  scales: {
    y: {
      ticks: { color: '#cbd5e1', font: { weight: 'bold' as const } },
      grid: { color: 'rgba(255,255,255,0.05)' },
    },
    x: {
      beginAtZero: true,
      ticks: {
        color: '#cbd5e1', font: { weight: 'bold' as const },
        // CORRIGIDO: Garante que a função callback seja executada
        callback: (value, index, ticks) => {
          return `${Number(value)}h`;
        }
      },
      grid: { color: 'rgba(255,255,255,0.1)' },
    },
  },
};

const chartDataValores = computed(() => ({
  labels: dadosFinanceirosCombinados.value.map((d) => d.code),
  datasets: [
    {
      label: 'Pagamento',
      data: dadosFinanceirosCombinados.value.map((d) => d.gasto),
      backgroundColor: '#4ade80',
      borderRadius: 6,
    },
    {
      label: 'Projetos',
      data: dadosFinanceirosCombinados.value.map((d) => d.destinado),
      backgroundColor: '#22d3ee',
      borderRadius: 6,
    }
  ]
}));

const chartOptionsValores = {
  indexAxis: 'y' as const,
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: true,
      position: 'top' as const,
      labels: {
        color: '#cbd5e1',
        font: {
          size: 14,
        }
      }
    },
    tooltip: {
      backgroundColor: 'rgba(0,0,0,0.7)',
      titleColor: '#fff',
      bodyColor: '#fff',
      callbacks: {
        label: ({ dataset, parsed }) => {
          let label = dataset.label || '';
          if (label) {
            label += ': ';
          }
          if (parsed.x !== null) {
            label += formatarMoeda(parsed.x);
          }
          return label;
        }
      }
    },
    datalabels: {
      color: '#ffffff',
      anchor: 'end' as const,
      align: 'end' as const,
      offset: -8,
      font: {
        weight: 'bold' as const,
        size: 12,
      },
      formatter: (value) => {
        if (value > 0) {
          return formatarMoeda(value);
        }
        return '';
      }
    }
  },
  scales: {
    y: {
      ticks: {
        color: '#cbd5e1',
        font: { weight: 'bold' as const }
      },
      grid: { color: 'rgba(255,255,255,0.05)' },
    },
    x: {
      ticks: {
        color: '#cbd5e1',
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        callback: (value, index, ticks) => {
            const num = Number(value);
            if (num >= 1000000) return 'R$' + (num / 1000000).toFixed(1) + 'M';
            if (num >= 1000) return 'R$' + (num / 1000) + 'K';
            return formatarMoeda(num);
        }
      },
      grid: { color: 'rgba(255,255,255,0.1)' },
    },
  },
};

const chartDataRankingPagamento = computed(() => ({
  labels: dadosRankingPagamento.value.map(d => d.code),
  datasets: [{
    label: 'Percentual Pago',
    data: dadosRankingPagamento.value.map(d => d.percentual),
    backgroundColor: '#06b6d4',
    borderRadius: 6,
  }]
}));

const chartOptionsRankingPagamento = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
        callbacks: {
            label: ({ dataset, parsed }) => `${dataset.label}: ${parsed.y.toFixed(2)}%`
        }
    },
    datalabels: {
        anchor: 'end' as const,
        align: 'top' as const,
        color: 'white',
        font: { weight: 'bold' as const },
        formatter: (value) => `${value.toFixed(2)}%`,
    }
  },
  scales: {
    y: {
        suggestedMax: 100,
        ticks: {
            color: '#cbd5e1',
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            callback: (value, index, ticks) => `${Number(value)}%`
        },
        grid: { color: 'rgba(255,255,255,0.1)' },
    },
    x: {
        ticks: {
            color: '#cbd5e1',
        },
        grid: { display: false },
    }
  }
};

const chartDataQuantidadeProcessos = computed(() => ({
  labels: dadosProcessosPorForca.value.map(d => d.code),
  datasets: [{
    label: 'Nº de Processos',
    data: dadosProcessosPorForca.value.map(d => d.total),
    backgroundColor: '#4f46e5',
    borderRadius: 6,
  }]
}));

const chartOptionsQuantidadeProcessos = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
        callbacks: {
            label: ({ dataset, parsed }) => `${dataset.label}: ${parsed.y}`
        }
    },
    datalabels: {
        anchor: 'end' as const,
        align: 'top' as const,
        color: 'white',
        font: { weight: 'bold' as const },
        formatter: (value) => value,
    }
  },
  scales: {
    y: {
      beginAtZero: true,
      ticks: {
        color: '#cbd5e1',
        stepSize: 1,
      },
      grid: { color: 'rgba(255,255,255,0.1)' },
    },
    x: {
      ticks: {
        color: '#cbd5e1',
      },
      grid: { display: false },
    }
  }
};


const chartHeightEtapa = computed(() => {
  const itemsCount = dadosTempoMedioEtapa.value.length;
  if (itemsCount === 0) return 400;

  return Math.max(itemsCount *50, 400);
});

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
  let usuario = user.value;
  if (!usuario) {
    usuario = await fetchUser();
  }
  if (!usuario) {
    processos.value = [];
    return;
  }

  // Carrega processos para o dropdown do histórico
  // DENTRO DE onMounted()

const { data } = await supabase
  .from('processes')
  .select('id, nome_acao, codigo_transferegov, thematic_areas(id, code)') // <-- VERIFIQUE SE 'codigo_transferegov' ESTÁ AQUI
  .is('deleted_at', null)
  .order('created_at', { ascending: false });

  if (data) {
    processos.value = (data as Processo[]).map((proc) => {
      let area_code = '';
      if (Array.isArray(proc.thematic_areas) && proc.thematic_areas.length > 0) {
        area_code = proc.thematic_areas[0].code;
      } else if (proc.thematic_areas && typeof proc.thematic_areas === 'object') {
        area_code = (proc.thematic_areas as { code: string }).code;
      }
      return {
        id: proc.id,
        nome_acao: proc.nome_acao,
        area_code,
      };
    });
  }

  // Carrega todos os dados para os gráficos em paralelo para mais performance
  await fetchForcas();
  await carregarDadosDosGraficos();
});

const dadosFinanceirosCombinados = computed(() => {
  const mapa = new Map<string, { code: string; destinado: number; gasto: number}>()

  dadosValoresPorOrgao.value.forEach(orgao => {
    mapa.set(orgao.code, {
      code: orgao.code,
      destinado: orgao.valor_total || 0,
      gasto: 0,
    })
  })

  dadosGastosPorOrgao.value.forEach(gasto =>{
    if (mapa.has(gasto.code)) {
      mapa.get(gasto.code)!.gasto = gasto.total_gasto || 0;
    }
  });

  return Array.from(mapa.values()).sort((a,b) => b.destinado - a.destinado);
});

const dadosRankingPagamento = computed(() => {
  return dadosFinanceirosCombinados.value
    .map(orgao => ({
      code: orgao.code,

      percentual: orgao.destinado > 0 ? (orgao.gasto / orgao.destinado) * 100 : 0,
    }))
    .sort((a, b) => b.percentual - a.percentual);
})

// Adicione esta computed property
const processosFiltrados = computed(() =>
  queryHistorico.value === ''
    ? processos.value
    : processos.value.filter((processo) => {
        const nome = processo.nome_acao?.toLowerCase() || ''
        const sei = processo.codigo_transferegov?.toLowerCase() || ''
        const query = queryHistorico.value.toLowerCase()
        
        return nome.includes(query) || sei.includes(query)
      })
)

const queryHistorico = ref('')

// Importar funções de formatação do composable
// Usar formatarDataSimples para datas sem hora

// Formata a data/hora para exibição amigável com hora e minuto (específica para análises)

function limparSelecaoHistorico() {
  processoSelecionado.value = ''; // Limpa o valor selecionado
  queryHistorico.value = '';     // Limpa o texto do campo de busca
}

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
