<template>
  <div
    v-if="show"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40"
    @click.self="$emit('close')"
  >
    <div
      class="bg-gradient-to-br from-slate-900/95 to-blue-900/95 backdrop-blur-md border border-white/20 text-white rounded-xl shadow-2xl p-8 max-w-4xl w-full relative max-h-[90vh] flex flex-col"
    >
      <div class="flex items-center gap-4 mb-4">
  <div class="flex bg-slate-800/50 rounded-lg p-1">
    <button @click="trocarParaDetalhes" class="px-4 py-1.5 rounded-md font-medium text-slate-300 hover:text-white hover:bg-white/10">
      Detalhes
    </button>
    <button @click="trocarParaEtapas" class="px-4 py-1.5 rounded-md font-medium text-slate-300 hover:text-white hover:bg-white/10">
      Etapas
    </button>
    <button class="px-4 py-1.5 rounded-md font-medium bg-gradient-to-r from-teal-600 to-cyan-500 text-white">
      Registros
    </button>
  </div>
  <button @click="fecharModal" class="ml-auto p-2 rounded-full hover:bg-white/10 text-slate-400 hover:text-red-400 transition" title="Fechar">
    <svg class='w-6 h-6' fill='none' viewBox='0 0 24 24' stroke='currentColor' stroke-width='2'><path stroke-linecap='round' stroke-linejoin='round' d='M18 6L6 18M6 6l12 12'/></svg>
  </button>
</div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6 bg-white/5 p-4 rounded-lg">
        <div class="text-center">
          <p class="text-sm text-slate-300">Valor Total Destinado</p>
          <p class="text-2xl font-bold text-green-400">{{ formatarMoeda(processo.valor_total_destinado || 0) }}</p>
        </div>
        <div class="text-center">
          <p class="text-sm text-slate-300">Valor Total Utilizado</p>
          <p class="text-2xl font-bold text-red-400">{{ formatarMoeda(totalUtilizado) }}</p>
        </div>
        <div class="text-center">
          <p class="text-semibold text-slate-300">Saldo Restante</p>
          <p class="text-2xl font-bold text-teal-400">{{ formatarMoeda(saldoRestante) }}</p>
        </div>
      </div>

      <div class="flex-1 overflow-y-auto pr-2">
        <div class="bg-white/5 p-4 rounded-lg mb-6">
          <h3 class="font-semibold text-white mb-3">Adicionar Novo Registro de Gasto</h3>
          <form @submit.prevent="salvarRegistro" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label class="block text-sm font-medium text-slate-300 mb-1">Data de Solicitação</label>
                <input v-model="newRecord.request_date" type="date" class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white custom-date-input">
              </div>
              <div>
                <label class="block text-sm font-medium text-slate-300 mb-1">Data de Aquisição</label>
                <input v-model="newRecord.acquisition_date" type="date" class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white custom-date-input">
              </div>
              <div>
                <label class="block text-sm font-medium text-slate-300 mb-1">Valor Utilizado</label>
                <input v-model.number="newRecord.amount_used" type="number" step="0.01" placeholder="R$ 0,00" class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white" required>
              </div>
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-300 mb-1">Descrição dos Itens/Serviços</label>
              <textarea v-model="newRecord.description" rows="2" placeholder="Descreva o que foi adquirido..." class="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white"></textarea>
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-300 mb-1">Anexar Comprovante (Opcional)</label>
              <div class="flex items-center gap-4 bg-white/10 border border-white/20 rounded-lg px-3 py-2">
                <label for="record-file-input" class="px-3 py-1 bg-white/10 border border-white/20 rounded-md text-white text-sm font-semibold cursor-pointer hover:bg-white/20 transition">
                  Escolher Arquivo
                </label>
                <input id="record-file-input" type="file" @change="onFileChange" class="hidden" />
                <span class="text-sm text-slate-300 truncate">{{  newRecordFile?.name || 'Nenhum arquivo selecionado...'}}</span>
              </div>
            </div>

            <div class="flex justify-end">
              <button type="submit" :disabled="isSubmitting" class="px-5 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded-lg font-semibold shadow disabled:opacity-50 disabled:cursor-not-allowed">
                {{ isSubmitting ? 'Salvando...' : 'Salvar Registro' }}
              </button>
            </div>
          </form>
        </div>

        <div>
          <h3 class="font-semibold text-white mb-3">Registros Salvos</h3>
          <div v-if="loadingRecords" class="text-center p-4">Carregando...</div>
          <div v-else-if="records.length === 0" class="text-center text-slate-400 p-4">Nenhum registro de gasto encontrado.</div>
          <div v-else class="space-y-3">
            <div v-for="record in records" :key="record.id" class="bg-white/5 p-3 rounded-lg flex items-center justify-between gap-4">
  <div>
    <p class="font-semibold text-white">{{ record.description || 'Registro sem descrição' }}</p>
    <div class="flex items-center gap-4 text-sm text-slate-300">
      <span>Solicitado: {{ formatarData(record.request_date) }}</span>
      <span>Adquirido: {{ formatarData(record.acquisition_date) }}</span>

      <a
        v-if="record.file_url"
        :href="record.file_url"
        target="_blank"
        class="flex items-center gap-1 text-teal-400 hover:text-teal-300 hover:underline"
        title="Ver anexo"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"></path></svg>
        Ver Comprovante
      </a>
    </div>
  </div>
  <p class="text-lg font-bold text-teal-300 flex-shrink-0">{{ formatarMoeda(record.amount_used) }}</p>
</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, watch, computed } from 'vue';
import { supabase } from '../services/supabase';
import { useAuth } from '../composables/useAuth';
import { useFormatters } from '../composables/useFormatters';


interface ProcessRecord {
  id: string;
  request_date: string | null;
  acquisition_date: string | null;
  amount_used: number;
  description: string | null;
  file_url?: string | null;      // Adicionado
  filename?: string | null;      // Adicionado
  storage_path?: string | null;  // Adicionado
}

// Props e Emits
const props = defineProps<{
  show: boolean;
  processo: { id: string; valor_total_destinado?: number };
}>();

const emit = defineEmits(['close', 'atualizar-processo', 'switch-to-detalhes', 'switch-to-etapas']);

function fecharModal() {
  emit('close');
}

function trocarParaEtapas() {
  emit('switch-to-etapas');
}

function trocarParaDetalhes() {
  emit('switch-to-detalhes');
}


// Serviços e Composables
const { user } = useAuth();
const { formatarValor: formatarMoeda, formatarData } = useFormatters();

// Estado do Componente
const records = ref<ProcessRecord[]>([]);
const loadingRecords = ref(false);
const isSubmitting = ref(false);
const newRecordFile = ref<File | null>(null)

const newRecord = reactive({
  request_date: '',
  acquisition_date: '',
  amount_used: null,
  description: '',
});

// Computed Property para o Total
const totalUtilizado = computed(() => {
  return records.value.reduce((sum, record) => sum + (record.amount_used || 0), 0);
});

const saldoRestante = computed(() =>{
  const destinado = props.processo.valor_total_destinado || 0;
  const utilizado = totalUtilizado.value;
  return destinado - utilizado;
});

// Funções

function onFileChange(event: Event){
  const target = event.target as HTMLInputElement;
  if(target.files && target.files.length > 0){
    newRecordFile.value = target.files[0]
  } else{
    newRecordFile.value = null
  }
}

async function fetchRecords() {
  if (!props.processo.id) return;
  loadingRecords.value = true;
  try {
    const { data, error } = await supabase
      .from('process_records')
      .select('*')
      .eq('process_id', props.processo.id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    records.value = data || [];
  } catch (err) {
    console.error('Erro ao buscar registros:', err);
    alert('Não foi possível carregar os registros.');
  } finally {
    loadingRecords.value = false;
  }
}

async function salvarRegistro() {
  if (!newRecord.amount_used) {
    alert('O campo "Valor Utilizado" é obrigatório.');
    return;
  }
  isSubmitting.value = true;

  const fileData = {
    file_url: null as string | null,
    filename: null as string | null,
    storage_path: null as string | null,
  };

  try {
    if (newRecordFile.value) {
      const file = newRecordFile.value;
      const sanitizedFileName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_');
      const filePath = `${props.processo.id}/records/${Date.now()}_${sanitizedFileName}`;

      const { error: uploadError } = await supabase.storage
        .from('documents')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      const { data: urlData } = supabase.storage.from('documents').getPublicUrl(filePath);
      fileData.file_url = urlData.publicUrl;
      fileData.filename = file.name;
      fileData.storage_path = filePath;
    }

    // 2. INSERE O REGISTRO NO BANCO DE DADOS
    const { error: insertError } = await supabase.from('process_records').insert([
      {
        process_id: props.processo.id,
        user_id: user.value?.id,
        request_date: newRecord.request_date || null,
        acquisition_date: newRecord.acquisition_date || null,
        amount_used: newRecord.amount_used,
        description: newRecord.description,
        // Adiciona os dados do arquivo (serão null se não houver anexo)
        ...fileData,
      },
    ]);

    if (insertError) throw insertError;

    // 3. LIMPA O FORMULÁRIO E RECARREGA A LISTA
    newRecord.request_date = '';
    newRecord.acquisition_date = '';
    newRecord.amount_used = null;
    newRecord.description = '';
    newRecordFile.value = null; // Limpa o arquivo também
    const fileInput = document.getElementById('record-file-input') as HTMLInputElement;
    if (fileInput) {
      fileInput.value = '';
    }

    await fetchRecords();

  } catch (err: unknown) {
    const error = err as Error;
    console.error('Erro ao salvar registro:', error);
    alert(`Não foi possível salvar o registro: ${error.message}`);
  } finally {
    isSubmitting.value = false;
  }
}

// Watcher para carregar os dados quando o modal abrir
watch(() => props.show, (newVal) => {
  if (newVal) {
    fetchRecords();
  }
});
</script>

<style scoped>
/* Estilo para o input de data ter o ícone de calendário branco */
.custom-date-input::-webkit-calendar-picker-indicator {
  filter: invert(1);
}
</style>
