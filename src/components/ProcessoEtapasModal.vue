<template>
  <!-- Modal de Etapas -->
  <div
    v-if="show"
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
      <!-- Navegação entre modais -->
      <div class="flex items-center gap-4 mb-4">
        <div class="flex bg-slate-800/50 rounded-lg p-1">
          <button
            @click="switchToDetalhes"
            class="px-4 py-1.5 rounded-md font-medium transition-all text-slate-300 hover:text-white hover:bg-white/10"
          >
            Detalhes
          </button>
          <button
            class="px-4 py-1.5 rounded-md font-medium transition-all bg-gradient-to-r from-teal-600 to-cyan-500 text-white"
          >
            Etapas
          </button>
        </div>
      </div>
      <h2 class="text-2xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent mb-2">
        {{ processo.nome_acao || 'Processo sem nome' }}
      </h2>
      <div class="mb-4 text-slate-300">
        Tempo total decorrido:
        <span class="font-semibold">{{ formatarSegundos(tempoTotal) }}</span>
      </div>
      <div class="flex justify-between items-center mb-4">
        <button
          v-if="etapaAtual > 0 && processo.status !== 'Concluído'"
          @click="voltarEtapa"
          class="px-4 py-2 bg-red-700 hover:bg-red-500 text-white rounded-lg font-semibold shadow transition"
        >
          Voltar à Etapa Anterior
        </button>

        <div v-else></div>

        <button
          v-if="processo.status !== 'Concluído'"
          @click="passarEtapa"
          class="px-4 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 hover:from-teal-700 hover:to-cyan-600 text-white rounded-lg font-semibold shadow transition"
        >
          {{ (processo.etapaAtual === processo.totalEtapas - 1 && processo.totalEtapas > 0) ? 'Concluir Processo' : 'Passar Etapa' }}
        </button>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div v-for="(etapa, idx) in etapas" :key="etapa.id">
          <div
            @click="toggleEtapa(etapa.id)"
            class="flex items-start gap-3 p-3 rounded-lg border border-white/20 bg-white/10 shadow-sm relative cursor-pointer hover:border-teal-400/50 transition-all"
            :class="{ 'border-teal-400 bg-teal-600/20': idx === etapaAtual }"
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
              <div class="flex items-center justify-between">
                <h3 class="font-semibold text-white">{{ etapa.nome }}</h3>
                <div class="flex items-center gap-1">
                  <span v-if="idx === etapaAtual && !etapa.ended_at" class="text-xs text-teal-400 font-semibold">
                    {{ formatarSegundos(tempoEtapaAtual) }}
                  </span>
                  <span v-else-if="etapa.accumulated_duration_seconds" class="text-xs text-slate-400">
                    {{ formatarSegundos(etapa.accumulated_duration_seconds) }}
                  </span>
                  <svg v-if="etapaExpandidaId === etapa.id" class="w-4 h-4 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"/></svg>
                  <svg v-else class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
                </div>
              </div>
              <div class="text-xs text-slate-400 flex items-center gap-2">
                <span v-if="etapa.started_at">Iniciado: {{ formatarData(etapa.started_at) }}</span>
                <span v-if="etapa.ended_at">Finalizado: {{ formatarData(etapa.ended_at) }}</span>
              </div>
            </div>
          </div>
          <div v-if="etapaExpandidaId === etapa.id" class="pl-8 pr-2 pt-3 pb-2 bg-slate-800/50 rounded-b-lg">
            <div v-if="etapa.checklist && etapa.checklist.length > 0" class="space-y-2 mb-3">
              <div v-for="item in etapa.checklist" :key="item.id" class="flex items-center justify-between group">
                <label class="flex items-center gap-3 text-sm text-slate-200 cursor-pointer">
                  <input
                    type="checkbox"
                    v-model="item.is_completed"
                    @change="toggleChecklistItem(item)"
                    @click.stop
                    class="w-5 h-5 accent-teal-500 bg-slate-700 border-slate-600 rounded"
                  />
                  <span :class="{ 'line-through text-slate-500': item.is_completed }">
                    {{ item.task_description }}
                  </span>
                </label>
                <button @click.stop="excluirSubEtapa(etapa, item.id)" class="text-slate-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity">
                   <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
              </div>
            </div>
            <p v-else class="text-sm text-slate-500 text-center mb-3">Nenhuma subtarefa adicionada.</p>
            <div class="flex items-center gap-2">
              <input
                v-model="novaSubEtapaTexto"
                @keyup.enter="adicionarSubEtapa(etapa)"
                @click.stop
                type="text"
                placeholder="Adicionar nova subtarefa..."
                class="flex-1 px-2 py-1 bg-slate-900/80 border border-slate-600 rounded text-white placeholder:text-slate-500 focus:outline-none focus:ring-1 focus:ring-teal-400 text-sm"
              />
              <button @click.stop="adicionarSubEtapa(etapa)" :disabled="carregandoChecklist" class="px-3 py-1 bg-teal-600 text-white rounded text-sm font-semibold hover:bg-teal-500 disabled:opacity-50">
                Add
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, defineProps, defineEmits, computed, watchEffect, onMounted, onUnmounted, watch } from 'vue'
import { tempoGastoEtapa, tempoTotalProcesso } from '../composables/useEtapaTimer'
import { buscarEtapasDoProcesso, registrarEventoHistorico } from '../services/auth'
import { supabase } from '../services/supabase'
import { useAuth } from '../composables/useAuth'
import { useFormatters } from '../composables/useFormatters'

const { } = useAuth() // Removido user e fetchUser pois não são utilizados

// Importar funções de formatação do composable
const { formatarData, formatarSegundos } = useFormatters()



// NOVA interface para o item do checklist
interface ChecklistItem {
  id: string;
  task_description: string;
  is_completed: boolean;
  process_step_id: string;
}

// ATUALIZE a interface Etapa para incluir o checklist
interface Etapa {
  id: string;
  nome: string;
  descricao: string;
  cor: string;
  started_at?: string;
  ended_at?: string;
  is_current?: boolean;
  step_order?: number;
  inicio?: number | null;
  fim?: number | null;
  accumulated_duration_seconds?: number;
  checklist: ChecklistItem[];
}

// Props e emits
const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  processo: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['close', 'atualizar-processo', 'switch-to-detalhes'])

// Estado do modal
const etapas = ref<Etapa[]>([])
const etapaAtual = ref(0)
const carregandoEtapas = ref(false)
const erroEtapas = ref('')
const tempoEtapaAtual = ref(0)
let timerInterval = null

// NOVOS estados para controlar a UI do checklist
const etapaExpandidaId = ref<string | null>(null)
const novaSubEtapaTexto = ref('')
const carregandoChecklist = ref(false)

// Computed properties
const tempoTotal = computed(() => tempoTotalProcesso(etapas.value))

// Funções
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
      (e: Record<string, unknown>) => ({
        id: e.id as string,
        nome: (e.step_templates && typeof e.step_templates === 'object' && 'name' in e.step_templates) ? (e.step_templates as { name?: string }).name || '' : '',
        descricao: '',
        cor: '#2196f3',
        started_at: e.started_at as string | undefined,
        ended_at: e.ended_at as string | undefined,
        is_current: e.is_current as boolean | undefined,
        step_order: e.step_order as number | undefined,
        inicio: e.started_at ? new Date(e.started_at as string).getTime() : null,
        fim: e.ended_at ? new Date(e.ended_at as string).getTime() : null,
        accumulated_duration_seconds: e.accumulated_duration_seconds as number || 0,
        checklist: Array.isArray(e.step_checklist_items) ? e.step_checklist_items as ChecklistItem[] : [],
      })
    )
    etapaAtual.value = data.findIndex((e: Record<string, unknown>) => Boolean(e.is_current))
    if (etapaAtual.value === -1) etapaAtual.value = 0
  }
  carregandoEtapas.value = false
}

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

// Função para expandir/recolher uma etapa
function toggleEtapa(etapaId: string) {
  if (etapaExpandidaId.value === etapaId) {
    etapaExpandidaId.value = null;
  } else {
    etapaExpandidaId.value = etapaId;
  }
}

// Função para adicionar uma nova subtarefa
async function adicionarSubEtapa(etapa: Etapa) {
  if (!novaSubEtapaTexto.value.trim()) return;
  carregandoChecklist.value = true;
  const { data, error } = await supabase
    .from('step_checklist_items')
    .insert({
      process_step_id: etapa.id,
      task_description: novaSubEtapaTexto.value
    })
    .select()
    .single();
  if (error) {
    console.error('Erro ao adicionar subtarefa:', error);
  } else if (data) {
    etapa.checklist.push(data);
    novaSubEtapaTexto.value = '';
  }
  carregandoChecklist.value = false;
}

// Função para excluir uma subtarefa
async function excluirSubEtapa(etapa: Etapa, itemId: string) {
  const { error } = await supabase
    .from('step_checklist_items')
    .delete()
    .eq('id', itemId);
  if (error) {
    console.error('Erro ao excluir subtarefa:', error);
  } else {
    etapa.checklist = etapa.checklist.filter(item => item.id !== itemId);
  }
}

// Função para marcar/desmarcar um item do checklist
async function toggleChecklistItem(item: ChecklistItem) {
  const { error } = await supabase
    .from('step_checklist_items')
    .update({ is_completed: item.is_completed })
    .eq('id', item.id);
  if (error) {
    console.error('Erro ao atualizar status da subtarefa:', error);
    // Reverter a alteração local em caso de erro
    item.is_completed = !item.is_completed;
  }
}

// Copie esta função inteira...
async function passarEtapa() {
  if (!props.processo.id) return;

  const isFinalStep = props.processo.etapaAtual === props.processo.totalEtapas - 1 && props.processo.totalEtapas > 0;

  const { error } = await supabase.rpc('avancar_etapa', { processo_id: props.processo.id });

  if (!error) {
    if (isFinalStep) {
      await registrarEventoHistorico(props.processo.id, 'Processo Concluído.');
    } else {
      const { data: etapas } = await buscarEtapasDoProcesso(props.processo.id);
      if (etapas && etapas.length > 0) {
        const etapaAtualIdx = etapas.findIndex(e => e.is_current);
        if (etapaAtualIdx !== -1) {
          const nomeNovaEtapa = etapas[etapaAtualIdx].step_templates?.name || 'etapa desconhecida';
          await registrarEventoHistorico(props.processo.id, `Etapa avançada para "${nomeNovaEtapa}".`);

          const processoAtualizado = {
             ...props.processo,
            etapaAtualNome: nomeNovaEtapa,
            etapaAtual: etapaAtualIdx,
            progresso: etapaAtualIdx > 0 && props.processo.totalEtapas > 1 ?
            Math.round((etapaAtualIdx / (props.processo.totalEtapas - 1)) * 100) : 0,
            // Atualiza o status se for a última etapa
            status: isFinalStep ? 'Concluído' : props.processo.status
          };

          // Recarrega as etapas no modal para refletir a mudança
          await carregarEtapas();
          emit('atualizar-processo', processoAtualizado);
          return;
        }
      }
    }
    // Se for o caso de conclusão, emite a atualização para o pai
    emit('atualizar-processo');
    // Recarrega as etapas no modal
    await carregarEtapas();
  } else {
    console.error("Erro ao avançar etapa:", error);
    alert("Ocorreu um erro ao tentar avançar a etapa.");
  }
}

async function voltarEtapa() {
  if (!props.processo.id) return;
  const { error } = await supabase.rpc('devolver_etapa', { processo_id_param: props.processo.id });
  if (error) {
    console.error('Erro ao voltar etapa:', error);
    alert('Erro ao voltar etapa: ' + (error.message || error.details || 'Erro desconhecido'));
    return;
  }
  // Buscar etapas atualizadas
  const { data: etapasData, error: etapasError } = await buscarEtapasDoProcesso(props.processo.id);
  if (etapasError) {
    console.error('Erro ao buscar etapas após voltar:', etapasError);
    alert('Erro ao buscar etapas: ' + (etapasError.message || etapasError.details || 'Erro desconhecido'));
    return;
  }
  if (etapasData && etapasData.length > 0) {
    const etapaAtualIdx = etapasData.findIndex(e => e.is_current);
    if (etapaAtualIdx !== -1) {
      const nomeEtapa = etapasData[etapaAtualIdx].step_templates?.name || 'etapa desconhecida';
      await registrarEventoHistorico(props.processo.id, `Etapa devolvida para "${nomeEtapa}".`);
    }
  }
  await carregarEtapas();

  // Criar um objeto com as atualizações em vez de emitir apenas o evento
  if (etapasData && etapasData.length > 0) {
    const etapaAtualIdx = etapasData.findIndex(e => e.is_current);
    if (etapaAtualIdx !== -1) {
      const nomeEtapa = etapasData[etapaAtualIdx].step_templates?.name || 'etapa desconhecida';
      const processoAtualizado = {
        ...props.processo,
        etapaAtualNome: nomeEtapa,
        etapaAtual: etapaAtualIdx,
        progresso: etapaAtualIdx > 0 && props.processo.totalEtapas > 1 ?
          Math.round((etapaAtualIdx / (props.processo.totalEtapas - 1)) * 100) : 0
      };
      emit('atualizar-processo', processoAtualizado);
      return;
    }
  }
  emit('atualizar-processo');
}

// Função para fechar o modal
function fecharEtapas() {
  emit('close')
}

// Função para alternar para o modal de detalhes
function switchToDetalhes() {
  emit('switch-to-detalhes')
}

// A função formatarData foi removida e agora é importada do composable useFormatters

// Watchers e lifecycle hooks
watchEffect(() => {
  startTimer()
})

watch(() => props.show, async (newVal) => {
  if (newVal) {
    await carregarEtapas()
  }
})

onMounted(() => {
  if (props.show) {
    carregarEtapas()
  }
  startTimer()
})

onUnmounted(() => {
  stopTimer()
})
</script>
