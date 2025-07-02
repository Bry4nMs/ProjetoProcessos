import { createRouter, createWebHistory } from 'vue-router'
import ProcessosView from '../views/ProcessosView.vue'
import LoginView from '../views/LoginView.vue'
import CadastroProcessoView from '../views/CadastroProcessoView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'processos',
      component: ProcessosView,
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
    },
    {
      path: '/processos/novo',
      name: 'cadastro-processo',
      component: CadastroProcessoView,
    },
  ],
})

export default router
