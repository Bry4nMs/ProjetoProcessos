<template>
  <AppLayout>
    <div class="min-h-screen flex justify-center items-stretch bg-abyss-deep px-8">
      <div class="w-full bg-white shadow-lg p-10 rounded-xl">
        <h1 class="text-3xl font-bold text-abyss-primary mb-4">Minha Conta</h1>
        <p class="text-abyss-secondary mb-6">Gerencie suas informações pessoais e configurações.</p>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <!-- Informações do Usuário -->
          <div class="bg-abyss-light p-6 rounded-lg shadow">
            <h2 class="text-xl font-semibold text-abyss-primary mb-4">Informações Pessoais</h2>
            <div class="space-y-4">
              <div>
                <label class="block text-abyss-dark font-medium mb-2">Nome</label>
                <input
                  v-model="userInfo.name"
                  type="text"
                  class="w-full px-3 py-2 border border-abyss-primary rounded focus:outline-none focus:ring-2 focus:ring-abyss-primary"
                  placeholder="Seu nome completo"
                />
              </div>
              <div>
                <label class="block text-abyss-dark font-medium mb-2">Email</label>
                <input
                  v-model="userInfo.email"
                  type="email"
                  class="w-full px-3 py-2 border border-abyss-primary rounded focus:outline-none focus:ring-2 focus:ring-abyss-primary"
                  placeholder="seu@email.com"
                  disabled
                />
              </div>
              <div>
                <label class="block text-abyss-dark font-medium mb-2">Telefone</label>
                <input
                  v-model="userInfo.phone"
                  type="tel"
                  class="w-full px-3 py-2 border border-abyss-primary rounded focus:outline-none focus:ring-2 focus:ring-abyss-primary"
                  placeholder="(00) 00000-0000"
                />
              </div>
              <div>
                <label class="block text-abyss-dark font-medium mb-2">Setor</label>
                <select
                  v-model="userInfo.setor_id"
                  class="w-full px-3 py-2 border border-abyss-primary rounded focus:outline-none focus:ring-2 focus:ring-abyss-primary"
                >
                  <option value="">Selecione o setor</option>
                  <option v-for="setor in setores" :key="setor.id" :value="setor.id">
                    {{ setor.nome }}
                  </option>
                </select>
              </div>
            </div>
            <button
              @click="salvarInformacoes"
              class="mt-4 px-4 py-2 bg-abyss-primary text-white rounded font-semibold hover:bg-abyss-secondary transition"
            >
              Salvar Alterações
            </button>
          </div>

          <!-- Configurações da Conta -->
          <div class="bg-abyss-light p-6 rounded-lg shadow">
            <h2 class="text-xl font-semibold text-abyss-primary mb-4">Configurações</h2>
            <div class="space-y-4">
              <div>
                <label class="block text-abyss-dark font-medium mb-2">Alterar Senha</label>
                <input
                  v-model="novaSenha"
                  type="password"
                  class="w-full px-3 py-2 border border-abyss-primary rounded focus:outline-none focus:ring-2 focus:ring-abyss-primary"
                  placeholder="Nova senha"
                />
              </div>
              <div>
                <label class="block text-abyss-dark font-medium mb-2">Confirmar Nova Senha</label>
                <input
                  v-model="confirmarSenha"
                  type="password"
                  class="w-full px-3 py-2 border border-abyss-primary rounded focus:outline-none focus:ring-2 focus:ring-abyss-primary"
                  placeholder="Confirme a nova senha"
                />
              </div>
            </div>
            <button
              @click="alterarSenha"
              class="mt-4 px-4 py-2 bg-abyss-primary text-white rounded font-semibold hover:bg-abyss-secondary transition"
            >
              Alterar Senha
            </button>
          </div>

          <!-- Estatísticas -->
          <div class="bg-abyss-light p-6 rounded-lg shadow md:col-span-2">
            <h2 class="text-xl font-semibold text-abyss-primary mb-4">Estatísticas da Conta</h2>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="text-center p-4 bg-white rounded-lg shadow">
                <div class="text-2xl font-bold text-abyss-primary">{{ estatisticas.totalProcessos }}</div>
                <div class="text-abyss-secondary">Total de Processos</div>
              </div>
              <div class="text-center p-4 bg-white rounded-lg shadow">
                <div class="text-2xl font-bold text-abyss-primary">{{ estatisticas.processosAtivos }}</div>
                <div class="text-abyss-secondary">Processos Ativos</div>
              </div>
              <div class="text-center p-4 bg-white rounded-lg shadow">
                <div class="text-2xl font-bold text-abyss-primary">{{ estatisticas.processosConcluidos }}</div>
                <div class="text-abyss-secondary">Processos Concluídos</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import AppLayout from '../components/Layout.vue'
import { ref, onMounted } from 'vue'
import { useAuth } from '../composables/useAuth'
import { supabase } from '../services/supabase'

const { user } = useAuth()

const userInfo = ref({
  name: '',
  email: '',
  phone: '',
  setor_id: ''
})
const setores = ref<{ id: number; nome: string }[]>([])

const novaSenha = ref('')
const confirmarSenha = ref('')

const estatisticas = ref({
  totalProcessos: 0,
  processosAtivos: 0,
  processosConcluidos: 0
})

onMounted(async () => {
  if (user.value) {
    userInfo.value.name = user.value.user_metadata?.name || ''
    userInfo.value.email = user.value.email || ''
    // Buscar perfil do usuário na tabela profiles
    const { data: perfil } = await supabase
      .from('profiles')
      .select('telefone, setor_id')
      .eq('id', user.value.id)
      .single()
    if (perfil) {
      userInfo.value.phone = perfil.telefone || ''
      userInfo.value.setor_id = perfil.setor_id || ''
    }
    // Buscar setores disponíveis
    const { data: setoresData } = await supabase
      .from('setores')
      .select('id, nome')
      .order('nome', { ascending: true })
    if (setoresData) setores.value = setoresData
    await carregarEstatisticas()
  }
})

async function carregarEstatisticas() {
  if (!user.value) return

  const { data: processos } = await supabase
    .from('processes')
    .select('status')
    .eq('user_id', user.value.id)

  if (processos) {
    estatisticas.value.totalProcessos = processos.length
    estatisticas.value.processosAtivos = processos.filter(p => p.status !== 'Concluído').length
    estatisticas.value.processosConcluidos = processos.filter(p => p.status === 'Concluído').length
  }
}

async function salvarInformacoes() {
  if (!user.value) return
  try {
    // Atualiza nome e telefone no auth (nome para user_metadata, telefone para profiles)
    const { error: errorAuth } = await supabase.auth.updateUser({
      data: {
        name: userInfo.value.name
      }
    })
    // Atualiza telefone e setor_id em profiles
    const { error: errorProfile } = await supabase
      .from('profiles')
      .update({
        telefone: userInfo.value.phone,
        setor_id: userInfo.value.setor_id
      })
      .eq('id', user.value.id)
    if (errorAuth || errorProfile) {
      alert('Erro ao salvar informações: ' + (errorAuth?.message || errorProfile?.message))
    } else {
      alert('Informações salvas com sucesso!')
    }
  } catch (error) {
    alert('Erro ao salvar informações')
  }
}

async function alterarSenha() {
  if (novaSenha.value !== confirmarSenha.value) {
    alert('As senhas não coincidem!')
    return
  }

  if (novaSenha.value.length < 6) {
    alert('A senha deve ter pelo menos 6 caracteres!')
    return
  }

  try {
    const { error } = await supabase.auth.updateUser({
      password: novaSenha.value
    })

    if (error) {
      alert('Erro ao alterar senha: ' + error.message)
    } else {
      alert('Senha alterada com sucesso!')
      novaSenha.value = ''
      confirmarSenha.value = ''
    }
  } catch (error) {
    alert('Erro ao alterar senha')
  }
}
</script>

<script lang="ts">
export default {
  name: 'MinhaContaView',
}
</script>
