<script setup lang="ts">
import { ref } from 'vue'
import { useAuth } from '../composables/useAuth'
// 1. IMPORTADO: Adicionamos o 'useRoute' para ler a URL
import { useRouter, useRoute } from 'vue-router'

const tab = ref<'login' | 'register'>('login')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const nome = ref('')

const { login, criarConta, error } = useAuth()
const feedback = ref('')
const router = useRouter()
// 2. ADICIONADO: Criamos a instância do 'route' para acessar os parâmetros da URL
const route = useRoute()

async function handleLogin(e: Event) {
  e.preventDefault()
  feedback.value = ''
  const { error: err } = await login(email.value, password.value)

  // 3. LÓGICA MODIFICADA: Todo este bloco foi alterado
  if (!err) {
    feedback.value = 'Login realizado com sucesso!'

    // Verifica se existe um parâmetro 'redirect' na URL
    const redirectPath = route.query.redirect as string;

    if (redirectPath) {
      // Se existir, redireciona o usuário para a página que ele queria acessar
      router.push(redirectPath);
    } else {
      // Se não, redireciona para a página principal padrão
      router.push('/processos');
    }
  }
}

async function handleRegister(e: Event) {
  e.preventDefault()
  feedback.value = ''
  if (password.value !== confirmPassword.value) {
    feedback.value = 'As senhas não coincidem.'
    return
  }
  const { error: err } = await criarConta(email.value, password.value, nome.value)
  if (!err) {
    feedback.value = 'Conta criada com sucesso!'
  }
}
</script>

<template>
  <div class="w-full max-w-md mx-auto bg-white rounded-lg shadow-lg p-8 mt-12">
    <div class="flex mb-8 border-b border-abyss-deep">
      <button
        class="flex-1 py-2 text-lg font-semibold focus:outline-none transition border-b-2"
        :class="
          tab === 'login'
            ? 'border-abyss-primary text-abyss-primary'
            : 'border-transparent text-abyss-secondary'
        "
        @click="tab = 'login'"
        type="button"
      >
        Login
      </button>
      <button
        class="flex-1 py-2 text-lg font-semibold focus:outline-none transition border-b-2"
        :class="
          tab === 'register'
            ? 'border-abyss-primary text-abyss-primary'
            : 'border-transparent text-abyss-secondary'
        "
        @click="tab = 'register'"
        type="button"
      >
        Criar Conta
      </button>
    </div>
    <div v-if="tab === 'login'">
      <div class="w-full max-w-md bg-white/20 backdrop-blur-md border border-white/30 rounded-2xl shadow-2xl p-8 space-y-6">
        <h1 class="text-3xl font-bold text-center bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">GECARE Processos</h1>
        <p class="text-center text-black font-bold">Faça login para continuar</p>
        <form @submit.prevent="handleLogin" class="space-y-4">
          <div>
            <label for="email" class="block mb-1 text-slate-800 font-semibold font-bold">Email</label>
            <input id="email" v-model="email" type="email" required class="w-full px-4 py-2 bg-white/80 border border-cyan-400 text-slate-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-400 placeholder:text-slate-400" placeholder="Digite seu email" />
          </div>
          <div>
            <label for="password" class="block mb-1 text-slate-800 font-semibold font-bold">Senha</label>
            <input id="password" v-model="password" type="password" required class="w-full px-4 py-2 bg-white/80 border border-cyan-400 text-slate-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-400 placeholder:text-slate-400" placeholder="Digite sua senha" />
          </div>
          <button type="submit" class="w-full px-4 py-3 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded-lg font-bold shadow-lg hover:from-teal-700 hover:to-cyan-600 transition">Entrar</button>
          <div class="flex justify-end">
            <a href="#" class="text-sm text-cyan-300 hover:underline">Esqueci minha senha</a>
          </div>
        </form>
      </div>
    </div>
    <div v-else>
      <div class="w-full max-w-md bg-white/20 backdrop-blur-md border border-white/30 rounded-2xl shadow-2xl p-8 space-y-6">
        <h1 class="text-3xl font-bold text-center bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">GECARE Processos</h1>
        <p class="text-center text-black font-bold">Crie sua conta para acessar</p>
        <form class="space-y-4" @submit.prevent="handleRegister">
          <div>
            <label class="block mb-1 text-slate-800 font-semibold font-bold">Nome</label>
            <input v-model="nome" type="text" required class="w-full px-4 py-2 bg-white/80 border border-cyan-400 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-400 placeholder:text-slate-400" placeholder="Digite seu nome" />
          </div>
          <div>
            <label class="block mb-1 text-slate-800 font-semibold font-bold">Email</label>
            <input v-model="email" type="email" required class="w-full px-4 py-2 bg-white/80 border border-cyan-400 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-400 placeholder:text-slate-400" placeholder="Digite seu email" />
          </div>
          <div>
            <label class="block mb-1 text-slate-800 font-semibold font-bold">Senha</label>
            <input v-model="password" type="password" required class="w-full px-4 py-2 bg-white/80 border border-cyan-400 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-400 placeholder:text-slate-400" placeholder="Digite sua senha" />
          </div>
          <div>
            <label class="block mb-1 text-slate-800 font-semibold font-bold">Confirmar Senha</label>
            <input
              v-model="confirmPassword"
              type="password"
              class="w-full px-4 py-2 bg-white/80 border border-cyan-400 text-slate-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-400 placeholder:text-slate-400"
              required
              placeholder="Confirme sua senha"
            />
          </div>
          <button type="submit" class="w-full px-4 py-3 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded-lg font-bold shadow-lg hover:from-teal-700 hover:to-cyan-600 transition">Criar Conta</button>
          <div class="flex justify-end">
            <a href="#" class="text-sm text-cyan-300 hover:underline" @click.prevent="tab = 'login'">Já tem uma conta? Faça login</a>
          </div>
          <div v-if="error" class="text-red-600 text-sm mt-2">{{ error }}</div>
          <div v-if="feedback && !error" class="text-green-600 text-sm mt-2">{{ feedback }}</div>
        </form>
      </div>
    </div>
  </div>
</template>
