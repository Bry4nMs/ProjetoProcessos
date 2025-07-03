<script setup lang="ts">
import { ref } from 'vue'
import { useAuth } from '../composables/useAuth'
import { useRouter } from 'vue-router'

const tab = ref<'login' | 'register'>('login')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const nome = ref('')

const { login, criarConta, loading, error } = useAuth()
const feedback = ref('')
const router = useRouter()

async function handleLogin(e: Event) {
  e.preventDefault()
  feedback.value = ''
  const { error: err } = await login(email.value, password.value)
  if (!err) {
    feedback.value = 'Login realizado com sucesso!'
    setTimeout(() => {
      router.push('/')
    }, 500)
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
      <form class="flex flex-col gap-4" @submit="handleLogin">
        <div>
          <label class="block text-gray-700 mb-1">Email</label>
          <input
            v-model="email"
            type="email"
            class="w-full px-4 py-2 rounded bg-white text-gray-900 border border-gray-300 focus:outline-none focus:ring-2 focus:ring-abyss-primary focus:border-abyss-primary"
            required
          />
        </div>
        <div>
          <label class="block text-gray-700 mb-1">Senha</label>
          <input
            v-model="password"
            type="password"
            class="w-full px-4 py-2 rounded bg-white text-gray-900 border border-gray-300 focus:outline-none focus:ring-2 focus:ring-abyss-primary focus:border-abyss-primary"
            required
          />
        </div>
        <button
          type="submit"
          class="mt-2 px-4 py-2 bg-abyss-primary text-white rounded font-bold shadow hover:bg-abyss-secondary transition"
          :disabled="loading"
        >
          Entrar
        </button>
        <div v-if="error" class="text-red-600 text-sm mt-2">{{ error }}</div>
        <div v-if="feedback && !error" class="text-green-600 text-sm mt-2">{{ feedback }}</div>
      </form>
    </div>
    <div v-else>
      <form class="flex flex-col gap-4" @submit="handleRegister">
        <div>
          <label class="block text-gray-700 mb-1">Nome</label>
          <input
            v-model="nome"
            type="text"
            class="w-full px-4 py-2 rounded bg-white text-gray-900 border border-gray-300 focus:outline-none focus:ring-2 focus:ring-abyss-primary focus:border-abyss-primary"
            required
          />
        </div>
        <div>
          <label class="block text-gray-700 mb-1">Email</label>
          <input
            v-model="email"
            type="email"
            class="w-full px-4 py-2 rounded bg-white text-gray-900 border border-gray-300 focus:outline-none focus:ring-2 focus:ring-abyss-primary focus:border-abyss-primary"
            required
          />
        </div>
        <div>
          <label class="block text-gray-700 mb-1">Senha</label>
          <input
            v-model="password"
            type="password"
            class="w-full px-4 py-2 rounded bg-white text-gray-900 border border-gray-300 focus:outline-none focus:ring-2 focus:ring-abyss-primary focus:border-abyss-primary"
            required
          />
        </div>
        <div>
          <label class="block text-gray-700 mb-1">Confirmar Senha</label>
          <input
            v-model="confirmPassword"
            type="password"
            class="w-full px-4 py-2 rounded bg-white text-gray-900 border border-gray-300 focus:outline-none focus:ring-2 focus:ring-abyss-primary focus:border-abyss-primary"
            required
          />
        </div>
        <button
          type="submit"
          class="mt-2 px-4 py-2 bg-abyss-primary text-white rounded font-bold shadow hover:bg-abyss-secondary transition"
          :disabled="loading"
        >
          Criar Conta
        </button>
        <div v-if="error" class="text-red-600 text-sm mt-2">{{ error }}</div>
        <div v-if="feedback && !error" class="text-green-600 text-sm mt-2">{{ feedback }}</div>
      </form>
    </div>
  </div>
</template>
