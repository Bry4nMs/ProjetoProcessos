import { createRouter, createWebHistory } from 'vue-router'
import ProcessosView from '../views/ProcessosView.vue'
import LoginView from '../views/LoginView.vue'
import CadastroProcessoView from '../views/CadastroProcessoView.vue'
import AnalisesView from '../views/AnalisesView.vue'
import MinhaContaView from '../views/MinhaContaView.vue'
import { obterUsuario } from '../services/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/processos',
    },
    {
      path: '/processos',
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
    {
      path: '/analises',
      name: 'analises',
      component: AnalisesView,
    },
    {
      path: '/minha-conta',
      name: 'minha-conta',
      component: MinhaContaView,
    },
    {
      path: '/acompanhamento-especial',
      name: 'AcompanhamentoEspecial',
      component: () => import('../views/AcompanhamentoEspecialView.vue'),
    },
    {
      path: '/admin',
      name: 'admin',
      component: () => import('../views/AdminView.vue'),
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  const publicPages = ['/login']
  const authRequired = !publicPages.includes(to.path)
  const user = await obterUsuario()
  if (authRequired && !user) {
    return next('/login')
  }
  next()
})

export default router
