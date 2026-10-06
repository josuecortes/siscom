// Alertas sonoros do siscom, feitos no navegador (Web Audio): curtos e baixos, só para chamar a atenção.
// Três sons diferentes, para a pessoa distinguir o que aconteceu:
//   notificacao  duas notas subindo ("din-don" agudo), do sino
//   mensagem     um "plim" grave e arredondado, do chat
//   painel       três notas em sequência, da TV de acompanhamento (uma sala inteira ouve)
//
// Cada notificação ou mensagem toca UMA vez, mesmo com várias abas abertas: a última que já tocou fica guardada
// no navegador (localStorage, comum a todas as abas). Abrir outra aba com algo ainda não lido não toca de novo.
const SONS = {
  notificacao: { onda: "sine", volume: 0.11, notas: [ [ 880, 0, 0.13 ], [ 1318.5, 0.11, 0.2 ] ] },
  mensagem: { onda: "triangle", volume: 0.13, notas: [ [ 523.25, 0, 0.09, 698.46 ], [ 698.46, 0.085, 0.14 ] ] },
  painel: { onda: "sine", volume: 0.2, notas: [ [ 783.99, 0, 0.16 ], [ 1046.5, 0.15, 0.16 ], [ 1318.5, 0.3, 0.3 ] ] }
}

let contexto = null

function audio() {
  const Contexto = window.AudioContext || window.webkitAudioContext
  if (!Contexto) return null
  contexto ||= new Contexto()
  return contexto
}

// O navegador só deixa tocar depois que a pessoa mexe na página: o primeiro clique ou tecla libera.
export function destravar() {
  const ctx = audio()
  if (ctx?.state === "suspended") ctx.resume().catch(() => {})
  return ctx
}

export function liberado() {
  return audio()?.state === "running"
}

// Toca agora (se o navegador deixar) e avisa a página com o evento "siscom:som".
export function tocar(tipo) {
  const som = SONS[tipo]
  if (!som) return
  // Os últimos toques desta página ficam anotados (para conferência e testes), com ou sem áudio liberado.
  window.siscomSonsTocados = [ ...(window.siscomSonsTocados || []), tipo ].slice(-20)
  document.dispatchEvent(new CustomEvent("siscom:som", { detail: { tipo } }))
  const ctx = destravar()
  if (!ctx || ctx.state !== "running") return

  const inicio = ctx.currentTime + 0.02
  som.notas.forEach(([ frequencia, quando, duracao, ate ]) => {
    const oscilador = ctx.createOscillator()
    const ganho = ctx.createGain()
    oscilador.type = som.onda
    oscilador.frequency.setValueAtTime(frequencia, inicio + quando)
    if (ate) oscilador.frequency.exponentialRampToValueAtTime(ate, inicio + quando + duracao)
    // Ataque rápido e queda suave: sem estalo no começo nem no fim.
    ganho.gain.setValueAtTime(0.0001, inicio + quando)
    ganho.gain.exponentialRampToValueAtTime(som.volume, inicio + quando + 0.012)
    ganho.gain.exponentialRampToValueAtTime(0.0001, inicio + quando + duracao)
    oscilador.connect(ganho).connect(ctx.destination)
    oscilador.start(inicio + quando)
    oscilador.stop(inicio + quando + duracao + 0.03)
  })
}

function ler(chave, padrao) {
  try {
    return JSON.parse(localStorage.getItem(chave)) ?? padrao
  } catch {
    return padrao
  }
}

function gravar(chave, valor) {
  try {
    localStorage.setItem(chave, JSON.stringify(valor))
  } catch { /* navegador sem armazenamento: toca sem lembrar */ }
}

// Uma aba de cada vez confere e marca (Web Locks), para duas abas não tocarem juntas a mesma coisa.
function sozinho(nome, tarefa) {
  if (navigator.locks?.request) return navigator.locks.request(`siscom-som-${nome}`, tarefa)
  return Promise.resolve(tarefa())
}

// Toca se este número (id da notificação ou da mensagem) ainda não tocou neste navegador.
export function tocarUmaVez(tipo, numero) {
  const id = Number(numero)
  if (!id) return
  const chave = `siscom-som-${tipo}`
  sozinho(tipo, () => {
    if (id <= Number(ler(chave, 0))) return
    gravar(chave, id)
    tocar(tipo)
  })
}

// Painel de TV: toca quando aparece na primeira coluna algo que não estava lá na última vez que esta tela foi
// vista (nova, reaberta ou liberada de novo). Atualizar a tela com as mesmas solicitações não toca. Na primeira
// vez que o painel abre num navegador, só anota o que já está lá.
export function tocarNovidades(nome, chaves) {
  const chave = `siscom-som-painel-${nome}`
  sozinho(`painel-${nome}`, () => {
    const antes = ler(chave, null)
    gravar(chave, chaves)
    if (antes && chaves.some((item) => !antes.includes(item))) tocar("painel")
  })
}

[ "pointerdown", "keydown" ].forEach((evento) => document.addEventListener(evento, destravar, { capture: true, passive: true }))
