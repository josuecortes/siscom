// Aviso na aba do navegador (título), para quem está em outra aba:
// - com algo não lido, o título começa com o total de notificações e mensagens: "(3) Início · Siscom";
// - quando chega algo novo com a aba escondida, o título alterna a cada 2 s com "🔔 Nova notificação" ou
//   "💬 Nova mensagem", até a pessoa voltar para a aba.
// Os números vêm dos balões do sino e do chat, que o tempo real redesenha (data-total).
const PREFIXO = /^\(\d+\) /

let base = ""
let anterior = null // { notificacoes, mensagens }
let aviso = null
let alternando = null
let mostrandoAviso = false

function numero(seletor) {
  return Number(document.querySelector(seletor)?.dataset.total || 0)
}

function contar() {
  return { notificacoes: numero("[data-sino-contador]"), mensagens: numero("[data-conversas-contador]") }
}

function tituloNormal() {
  const { notificacoes, mensagens } = contar()
  const total = notificacoes + mensagens
  return total > 0 ? `(${total}) ${base}` : base
}

function escrever(texto) {
  if (document.title !== texto) document.title = texto
}

function pararDeAlternar() {
  clearInterval(alternando)
  alternando = null
  aviso = null
  mostrandoAviso = false
  escrever(tituloNormal())
}

function alternar(texto) {
  aviso = texto
  if (alternando) return
  alternando = setInterval(() => {
    mostrandoAviso = !mostrandoAviso
    escrever(mostrandoAviso ? aviso : tituloNormal())
  }, 2000)
}

function atualizar() {
  if (!document.querySelector("#sino_notificacoes")) return // telas sem sino (login, painel de TV)

  const agora = contar()
  if (anterior && document.hidden) {
    if (agora.mensagens > anterior.mensagens) alternar("💬 Nova mensagem")
    else if (agora.notificacoes > anterior.notificacoes) alternar("🔔 Nova notificação")
  }
  anterior = agora
  if (!mostrandoAviso) escrever(tituloNormal())
}

// Cada página nova (ou atualização da página) traz o seu título: ele é a base.
function novaPagina() {
  base = document.title.replace(PREFIXO, "")
  atualizar()
}

let pendente = false
new MutationObserver(() => {
  if (pendente) return
  pendente = true
  requestAnimationFrame(() => { pendente = false; atualizar() })
}).observe(document.documentElement, { childList: true, subtree: true })

document.addEventListener("turbo:load", novaPagina)
document.addEventListener("turbo:render", novaPagina)
document.addEventListener("visibilitychange", () => { if (!document.hidden) pararDeAlternar() })
novaPagina()
