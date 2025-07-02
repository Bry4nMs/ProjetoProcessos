<script setup lang="ts">
import Layout from '../components/Layout.vue'
const anoAtual = new Date().getFullYear()
const anos = Array.from({ length: anoAtual - 2019 + 1 }, (_, i) => 2019 + i)
</script>

<template>
  <Layout>
    <div class="max-w-3xl mx-auto bg-white rounded-lg shadow-lg p-8 mt-8">
      <h1 class="text-2xl font-bold text-abyss-primary mb-6">Cadastro de Novo Processo</h1>
      <form class="flex flex-col gap-6">
        <div>
          <label class="block text-abyss-dark mb-1 font-semibold">Nome da Ação</label>
          <input
            type="text"
            class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            placeholder="Digite o nome da ação"
          />
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Área Temática</label>
            <select
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            >
              <option value="">Selecione</option>
              <option>VPSP</option>
              <option>ECV</option>
              <option>FISP</option>
              <option>EVM</option>
              <option>MQV</option>
              <option>RMVI</option>
            </select>
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Código Transferegov</label>
            <input
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="Digite o código"
            />
          </div>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Ano do FAF</label>
            <select
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            >
              <option value="">Selecione</option>
              <option v-for="ano in anos" :key="ano">{{ ano }}</option>
            </select>
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold"
              >Tipo de Natureza de Despesa</label
            >
            <select
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            >
              <option value="">Selecione</option>
              <option>Custeio</option>
              <option>Investimento</option>
            </select>
          </div>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Força Responsável</label>
            <select
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            >
              <option value="">Selecione</option>
              <option>PMGO</option>
              <option>PCGO</option>
              <option>CBMGO</option>
              <option>DGPP</option>
              <option>SPTC</option>
              <option>SPP</option>
            </select>
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold"
              >Data de Encaminhamento para Aprovação do MJSP</label
            >
            <input
              type="date"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            />
          </div>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Quantidade de Itens</label>
            <input
              type="number"
              min="0"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            />
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Descrição dos Itens</label>
            <textarea
              rows="2"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            ></textarea>
          </div>
        </div>
        <div>
          <label class="block text-abyss-dark mb-1 font-semibold">Destinação dos Itens</label>
          <textarea
            rows="2"
            class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          ></textarea>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Valor Inicial Padrão</label>
            <input
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="R$ 0,00"
            />
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Valor de Rendimentos</label>
            <input
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="R$ 0,00"
            />
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Valor de Economicidade</label>
            <input
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="R$ 0,00"
            />
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold"
              >Valor Total Destinado à Ação</label
            >
            <input
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="R$ 0,00"
            />
          </div>
        </div>
        <div>
          <label class="block text-abyss-dark mb-1 font-semibold">Descrição Geral da Ação</label>
          <textarea
            rows="4"
            class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          ></textarea>
        </div>
        <div>
          <label class="block text-abyss-dark mb-1 font-semibold"
            >Anexar Nota Técnica ou Documento de Aprovação</label
          >
          <input
            type="file"
            multiple
            class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep file:bg-abyss-primary file:text-abyss-black file:rounded file:px-4 file:py-2 file:mr-4"
          />
        </div>
        <div class="flex justify-end">
          <button
            type="button"
            class="px-6 py-3 bg-abyss-primary text-abyss-black rounded-lg shadow hover:bg-abyss-secondary transition font-bold"
          >
            Registrar Ação
          </button>
        </div>
      </form>
    </div>
  </Layout>
</template>
