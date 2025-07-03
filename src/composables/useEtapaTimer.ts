import { ref, computed, onMounted, onUnmounted } from 'vue'

export function useEtapaTimer(etapas, etapaAtualRef) {
  const now = ref(Date.now())
  let interval: ReturnType<typeof setInterval> | null = null

  onMounted(() => {
    interval = setInterval(() => {
      now.value = Date.now()
    }, 1000)
  })
  onUnmounted(() => {
    clearInterval(interval)
  })

  // Tempo da etapa atual
  const tempoEtapaAtual = computed(() => {
    const idx = etapaAtualRef.value
    const etapa = etapas.value[idx]
    if (!etapa || !etapa.inicio) return 0
    return Math.floor((now.value - etapa.inicio) / 1000)
  })

  // Tempo total do processo (soma das etapas já iniciadas)
  const tempoTotal = computed(() => {
    let total = 0
    for (let i = 0; i <= etapaAtualRef.value; i++) {
      const etapa = etapas.value[i]
      if (etapa && etapa.inicio) {
        if (i < etapaAtualRef.value) {
          // Etapas anteriores: diferença para a próxima etapa
          const next = etapas.value[i + 1]
          if (next && next.inicio) {
            total += Math.floor((next.inicio - etapa.inicio) / 1000)
          } else {
            total += Math.floor((now.value - etapa.inicio) / 1000)
          }
        } else {
          // Etapa atual: até agora
          total += Math.floor((now.value - etapa.inicio) / 1000)
        }
      }
    }
    return total
  })

  function formatarSegundos(seg) {
    const h = Math.floor(seg / 3600)
    const m = Math.floor((seg % 3600) / 60)
    const s = seg % 60
    return [h, m, s].map((v) => String(v).padStart(2, '0')).join(':')
  }

  return { tempoEtapaAtual, tempoTotal, formatarSegundos }
}
