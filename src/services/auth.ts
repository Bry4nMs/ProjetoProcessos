import { supabase } from './supabase'

export async function login(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  return { user: data?.user, session: data?.session, error }
}

export async function criarConta(email: string, password: string, nome?: string) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: nome ? { name: nome } : undefined,
    },
  })
  return { user: data?.user, session: data?.session, error }
}

export async function logout() {
  const { error } = await supabase.auth.signOut()
  return { error }
}

export async function obterUsuario() {
  const { data } = await supabase.auth.getUser()
  return data?.user
}

// Buscar etapas de um processo
export async function buscarEtapasDoProcesso(processId: string) {
  const { data, error } = await supabase
    .from('process_steps')
    .select('*, step_templates(name)')
    .eq('process_id', processId)
    .order('step_order', { ascending: true })
  return { data, error }
}

// Avançar etapa do processo
export async function avancarEtapa(processId: string, etapaAtual: number, totalEtapas: number) {
  // Marca a etapa atual como finalizada
  const { error: errorAtual } = await supabase
    .from('process_steps')
    .update({ ended_at: new Date().toISOString(), is_current: false })
    .eq('process_id', processId)
    .eq('step_order', etapaAtual)
    .eq('is_current', true)

  if (etapaAtual + 1 < totalEtapas) {
    // Marca a próxima etapa como atual e define started_at
    const { error: errorProx } = await supabase
      .from('process_steps')
      .update({ started_at: new Date().toISOString(), is_current: true })
      .eq('process_id', processId)
      .eq('step_order', etapaAtual + 1)
    return { error: errorAtual || errorProx }
  } else {
    // Se for a última etapa, pode atualizar status do processo para 'Concluído'
    const { error: errorProc } = await supabase
      .from('processes')
      .update({ status: 'Concluído' })
      .eq('id', processId)
    return { error: errorAtual || errorProc }
  }
}
