import { ref } from 'vue'
import {
  login as loginService,
  criarConta as criarContaService,
  logout as logoutService,
  obterUsuario,
} from '../services/auth'

const user = ref(null)
const loading = ref(false)
const error = ref<string | null>(null)

export function useAuth() {
  async function login(email: string, password: string) {
    loading.value = true
    error.value = null
    const { user: u, error: err } = await loginService(email, password)
    user.value = u
    error.value = err?.message || null
    loading.value = false
    return { user: u, error: err }
  }

  async function criarConta(email: string, password: string, nome?: string) {
    loading.value = true
    error.value = null
    const { user: u, error: err } = await criarContaService(email, password, nome)
    user.value = u
    error.value = err?.message || null
    loading.value = false
    return { user: u, error: err }
  }

  async function logout() {
    loading.value = true
    error.value = null
    const { error: err } = await logoutService()
    user.value = null
    error.value = err?.message || null
    loading.value = false
    return { error: err }
  }

  async function fetchUser() {
    loading.value = true
    error.value = null
    user.value = await obterUsuario()
    loading.value = false
    return user.value
  }

  return {
    user,
    loading,
    error,
    login,
    criarConta,
    logout,
    fetchUser,
  }
}
