// Formulário aberto por muito tempo (painel preenchido devagar) não perde o que foi digitado quando a sessão expira.
//
// 1. Enquanto a pessoa está mexendo na página, um "pulso" de tempos em tempos mantém a sessão viva e traz o
//    token de formulário atual (ele muda quando a pessoa entra de novo em outra aba).
// 2. Antes de enviar qualquer formulário que grava, se o último pulso não é recente, confere de novo:
//    - sessão ok: atualiza o token e envia;
//    - sessão expirada: NÃO envia. Avisa e oferece abrir o login em outra aba; o formulário fica como está.
//      Depois de entrar, é só clicar em salvar de novo.
// Só vale com alguém logado: o layout põe <meta name="sessao-pulso" content="/sessao/pulso">.
import { Turbo } from "@hotwired/turbo-rails"

const RECENTE = 2 * 60 * 1000 // um pulso vale por 2 minutos
const A_CADA = 5 * 60 * 1000 // com a pessoa ativa, renova a cada 5 minutos

let ultimoPulso = Date.now() // a página acabou de vir do servidor
let ultimaAtividade = Date.now()

const caminho = () => document.querySelector("meta[name='sessao-pulso']")?.content
const login = () => document.querySelector("meta[name='sessao-login']")?.content || "/users/sign_in"

function atualizarToken(token) {
  if (!token) return
  document.querySelector("meta[name='csrf-token']")?.setAttribute("content", token)
  document.querySelectorAll("input[name='authenticity_token']").forEach((campo) => { campo.value = token })
}

// "ok", "expirada" ou "sem_rede".
async function pulsar() {
  try {
    const resposta = await fetch(caminho(), { headers: { Accept: "application/json" }, credentials: "same-origin", cache: "no-store" })
    if (resposta.status === 401) return "expirada"
    if (!resposta.ok) return "sem_rede"
    atualizarToken((await resposta.json()).token)
    ultimoPulso = Date.now()
    return "ok"
  } catch {
    return "sem_rede"
  }
}

async function avisarExpirada() {
  const abrir = await Turbo.config.forms.confirm(
    "Você ficou muito tempo sem usar o sistema e a sessão expirou. O que você preencheu continua aqui: entre de novo em outra aba, volte para esta e clique em salvar outra vez.",
    { dataset: { confirmacaoTitulo: "Sessão expirada", confirmacaoRotulo: "Entrar em outra aba", confirmacaoTom: "primario" } }
  )
  if (abrir) window.open(login(), "_blank", "noopener")
}

document.addEventListener("submit", async (evento) => {
  const formulario = evento.target
  if (!caminho() || !(formulario instanceof HTMLFormElement)) return
  const metodo = (evento.submitter?.getAttribute("formmethod") || formulario.getAttribute("method") || "get").toLowerCase()
  if (metodo === "get" || formulario.dataset.sessaoConferida === "1") return delete formulario.dataset.sessaoConferida
  if (Date.now() - ultimoPulso < RECENTE) return

  // Segura o envio, confere a sessão e reenvia (com o mesmo botão e os mesmos arquivos).
  evento.preventDefault()
  evento.stopImmediatePropagation()
  const botao = evento.submitter
  const estado = await pulsar()
  if (estado === "expirada") return avisarExpirada()
  formulario.dataset.sessaoConferida = "1" // sem rede: deixa seguir, o navegador mostra o erro de conexão
  formulario.requestSubmit(botao?.isConnected ? botao : undefined)
}, true)

;[ "keydown", "pointerdown", "input" ].forEach((nome) => document.addEventListener(nome, () => { ultimaAtividade = Date.now() }, { capture: true, passive: true }))

setInterval(() => {
  if (!caminho() || document.hidden) return
  if (Date.now() - ultimaAtividade < A_CADA && Date.now() - ultimoPulso >= A_CADA) pulsar()
}, 60 * 1000)

// Cada página nova que chega do servidor já vem com sessão e token conferidos.
document.addEventListener("turbo:load", () => { ultimoPulso = Date.now() })
