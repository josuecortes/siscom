import { Controller } from "@hotwired/stimulus"
import { destravar, liberado, tocar, tocarNovidades } from "sons"

// Painel de TV do Transporte: relógio que anda sozinho, colunas que rolam sozinhas e contagem para a
// próxima atualização.
//
// Um ciclo: as colunas ficam paradas no topo (pausaTopo), rolam devagar até o fim e param lá (pausaFim);
// aí a tela atualiza e o ciclo recomeça do topo. O ciclo dura o intervalo padrão quando tudo cabe na
// tela; com colunas compridas ele cresce o bastante para a maior coluna rolar inteira na velocidade
// de leitura (pixels por segundo). Todas as colunas chegam ao fim juntas: as menores rolam mais devagar.
//
// Quando algo muda na operação, o quadro atualiza na hora (Turbo Streams) sem interromper a rolagem.
//
// Alerta sonoro: toca quando entra algo novo na primeira coluna (target `chegada`), uma vez por solicitação;
// atualizar a tela com as mesmas não toca de novo (ver sons.js).
export default class extends Controller {
  static targets = ["hora", "data", "contagem", "barra", "lista", "chegada", "som"]
  static values = {
    intervalo: { type: Number, default: 30 },
    nome: { type: String, default: "painel" },
    velocidade: { type: Number, default: 30 },
    pausaTopo: { type: Number, default: 5 },
    pausaFim: { type: Number, default: 4 }
  }

  connect() {
    this.medir = this.medir.bind(this)
    this.quadro = this.quadro.bind(this)
    this.conferirChegadas = this.conferirChegadas.bind(this)
    this.conferirChegadas()
    document.addEventListener("turbo:render", this.conferirChegadas) // a tela atualiza por morph: o elemento continua o mesmo
    document.addEventListener("turbo:render", this.medir)
    window.addEventListener("resize", this.medir)
    this.comecarCiclo()
    this.relogio = setInterval(() => this.passar(), 1000)
    this.animacao = requestAnimationFrame(this.quadro)
  }

  disconnect() {
    clearInterval(this.relogio)
    clearTimeout(this.esperaDasChegadas)
    document.removeEventListener("turbo:render", this.conferirChegadas)
    cancelAnimationFrame(this.animacao)
    document.removeEventListener("turbo:render", this.medir)
    window.removeEventListener("resize", this.medir)
  }

  // A cada vez que a primeira coluna é (re)desenhada: o que não estava lá antes toca o alerta.
  chegadaTargetConnected() {
    this.conferirChegadas()
  }

  conferirChegadas() {
    if (!this.hasChegadaTarget) return
    clearTimeout(this.esperaDasChegadas) // um redesenho troca vários elementos: confere uma vez só, no fim
    this.esperaDasChegadas = setTimeout(() => {
      if (!this.hasChegadaTarget) return
      tocarNovidades(this.nomeValue, [...this.chegadaTarget.querySelectorAll("[data-chave]")].map((cartao) => cartao.dataset.chave))
      this.mostrarSom()
    }, 150)
  }

  ligarSom() {
    const ctx = destravar()
    if (!ctx) return
    ctx.resume().then(() => {
      tocar("painel") // a pessoa ouve como é o alerta
      this.mostrarSom()
    }).catch(() => {})
  }

  mostrarSom() {
    if (this.hasSomTarget) this.somTarget.textContent = liberado() ? "Som: ligado" : "Som: ligar"
  }

  comecarCiclo() {
    this.inicio = performance.now()
    this.listaTargets.forEach((lista) => { lista.scrollTop = 0 })
    this.medir()
    this.mostrar()
  }

  // Quanto dura o ciclo, pelo tanto que a maior coluna tem para rolar agora.
  medir() {
    const sobra = Math.max(0, ...this.listaTargets.map((lista) => lista.scrollHeight - lista.clientHeight))
    const rolando = sobra > 0 ? this.pausaTopoValue + sobra / this.velocidadeValue + this.pausaFimValue : 0
    this.ciclo = Math.ceil(Math.max(this.intervaloValue, rolando))
  }

  decorrido() {
    return (performance.now() - this.inicio) / 1000
  }

  // A cada quadro, põe cada coluna na altura que corresponde ao ponto do ciclo.
  quadro() {
    const rolagem = this.ciclo - this.pausaTopoValue - this.pausaFimValue
    const avanco = Math.min(1, Math.max(0, (this.decorrido() - this.pausaTopoValue) / rolagem))
    this.listaTargets.forEach((lista) => {
      const sobra = lista.scrollHeight - lista.clientHeight
      if (sobra > 0) lista.scrollTop = sobra * avanco
    })
    this.animacao = requestAnimationFrame(this.quadro)
  }

  passar() {
    if (this.decorrido() >= this.ciclo) {
      window.Turbo.visit(window.location.href, { action: "replace" })
      this.comecarCiclo()
    }
    this.mostrar()
  }

  mostrar() {
    const agora = new Date()
    const fuso = { timeZone: "America/Belem" }
    const faltam = Math.max(0, Math.ceil(this.ciclo - this.decorrido()))
    if (this.hasHoraTarget) this.horaTarget.textContent = agora.toLocaleTimeString("pt-BR", { ...fuso, hour: "2-digit", minute: "2-digit", second: "2-digit" })
    if (this.hasDataTarget) this.dataTarget.textContent = agora.toLocaleDateString("pt-BR", { ...fuso, weekday: "long", day: "2-digit", month: "long" })
    if (this.hasContagemTarget) this.contagemTarget.textContent = faltam >= 60 ? `${Math.floor(faltam / 60)} min ${faltam % 60} s` : `${faltam} s`
    if (this.hasBarraTarget) this.barraTarget.style.width = `${(faltam / this.ciclo) * 100}%`
    this.mostrarSom()
  }
}
