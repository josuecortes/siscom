import { Controller } from "@hotwired/stimulus"

// Painel de TV do Transporte: relógio que anda sozinho, colunas que rolam sozinhas e contagem para a
// próxima atualização.
//
// Um ciclo: as colunas ficam paradas no topo (pausaTopo), rolam devagar até o fim e param lá (pausaFim);
// aí a tela atualiza e o ciclo recomeça do topo. O ciclo dura o intervalo padrão quando tudo cabe na
// tela; com colunas compridas ele cresce o bastante para a maior coluna rolar inteira na velocidade
// de leitura (pixels por segundo). Todas as colunas chegam ao fim juntas: as menores rolam mais devagar.
//
// Quando algo muda na operação, o quadro atualiza na hora (Turbo Streams) sem interromper a rolagem.
export default class extends Controller {
  static targets = ["hora", "data", "contagem", "barra", "lista"]
  static values = {
    intervalo: { type: Number, default: 30 },
    velocidade: { type: Number, default: 30 },
    pausaTopo: { type: Number, default: 5 },
    pausaFim: { type: Number, default: 4 }
  }

  connect() {
    this.medir = this.medir.bind(this)
    this.quadro = this.quadro.bind(this)
    document.addEventListener("turbo:render", this.medir)
    window.addEventListener("resize", this.medir)
    this.comecarCiclo()
    this.relogio = setInterval(() => this.passar(), 1000)
    this.animacao = requestAnimationFrame(this.quadro)
  }

  disconnect() {
    clearInterval(this.relogio)
    cancelAnimationFrame(this.animacao)
    document.removeEventListener("turbo:render", this.medir)
    window.removeEventListener("resize", this.medir)
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
  }
}
