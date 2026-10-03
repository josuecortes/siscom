import { Controller } from "@hotwired/stimulus"

// Campo de busca com sugestões (porta do AutocompleteSearchField do seed).
// - A partir de 3 letras, lista o que combina com o texto.
// - Se nada combinar (ou com menos de 3 letras), mostra a lista em ordem alfabética.
// - O valor escolhido vai para um campo oculto; mudar o texto desfaz a escolha.
// O servidor responde { opcoes: [{ valor, rotulo, subtitulo }], todas: bool, restantes: n }.
export default class extends Controller {
  static targets = ["texto", "valor", "lista"]
  static values = { url: String, minimo: { type: Number, default: 3 }, vazio: { type: String, default: "Nada cadastrado." } }

  connect() {
    this.indice = -1
    this.fora = (evento) => { if (!this.element.contains(evento.target)) this.fechar() }
    document.addEventListener("click", this.fora)
  }

  disconnect() {
    document.removeEventListener("click", this.fora)
    clearTimeout(this.espera)
    this.requisicao?.abort()
  }

  abrir() {
    if (this.listaTarget.hidden && !this.valorTarget.value) this.buscar()
  }

  digitar() {
    this.valorTarget.value = ""
    clearTimeout(this.espera)
    this.espera = setTimeout(() => this.buscar(), 200)
  }

  async buscar() {
    const texto = this.textoTarget.value.trim()
    const url = new URL(this.urlValue, window.location.origin)
    if (texto.length >= this.minimoValue) url.searchParams.set("q", texto)

    this.requisicao?.abort()
    this.requisicao = new AbortController()
    try {
      const resposta = await fetch(url, { headers: { Accept: "application/json" }, signal: this.requisicao.signal })
      if (!resposta.ok) throw new Error(String(resposta.status))
      this.mostrar(await resposta.json(), texto)
    } catch (erro) {
      if (erro.name !== "AbortError") this.aviso("Não foi possível carregar as opções. Tente de novo.")
    }
  }

  mostrar(dados, texto) {
    this.listaTarget.replaceChildren()
    this.indice = -1

    if (dados.opcoes.length === 0) return this.aviso(this.vazioValue)
    if (dados.todas && texto.length >= this.minimoValue) {
      this.listaTarget.append(this.nota(`Nada encontrado para "${texto}". Lista completa:`))
    }

    dados.opcoes.forEach((opcao, posicao) => {
      const botao = document.createElement("button")
      botao.type = "button"
      botao.setAttribute("role", "option")
      botao.id = `${this.textoTarget.id}_opcao_${posicao}`
      botao.dataset.valor = opcao.valor
      botao.dataset.rotulo = opcao.rotulo
      botao.dataset.action = "autocomplete#escolher"
      botao.className = "flex w-full flex-col items-start gap-0.5 border-b border-[var(--border-subtle)] px-4 py-3 text-left text-sm text-[var(--text-primary)] last:border-b-0 hover:bg-[var(--surface-subtle)] aria-selected:bg-[var(--surface-subtle)]"
      const rotulo = document.createElement("span")
      rotulo.textContent = opcao.rotulo
      botao.append(rotulo)
      if (opcao.subtitulo) {
        const subtitulo = document.createElement("span")
        subtitulo.className = "text-xs text-[var(--text-muted)]"
        subtitulo.textContent = opcao.subtitulo
        botao.append(subtitulo)
      }
      this.listaTarget.append(botao)
    })

    if (dados.restantes > 0) this.listaTarget.append(this.nota(`Mais ${dados.restantes} na lista. Continue digitando para encontrar.`))
    this.listaTarget.hidden = false
    this.textoTarget.setAttribute("aria-expanded", "true")
  }

  nota(texto) {
    const nota = document.createElement("div")
    nota.className = "border-b border-[var(--border-subtle)] px-4 py-2 text-xs text-[var(--text-muted)] last:border-b-0"
    nota.textContent = texto
    return nota
  }

  aviso(texto) {
    const aviso = document.createElement("div")
    aviso.className = "px-4 py-3 text-sm text-[var(--text-secondary)]"
    aviso.textContent = texto
    this.listaTarget.replaceChildren(aviso)
    this.listaTarget.hidden = false
  }

  escolher(evento) {
    const opcao = evento.currentTarget
    // Cancela buscas ainda em andamento, para a lista não reabrir depois da escolha.
    clearTimeout(this.espera)
    this.requisicao?.abort()
    this.valorTarget.value = opcao.dataset.valor
    this.textoTarget.value = opcao.dataset.rotulo
    this.fechar()
    this.valorTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  teclar(evento) {
    const opcoes = [...this.listaTarget.querySelectorAll("[role='option']")]
    if (evento.key === "Escape") return this.fechar()
    if (evento.key === "ArrowDown" && this.listaTarget.hidden) return this.buscar()
    if (opcoes.length === 0) return

    if (evento.key === "ArrowDown") this.indice = (this.indice + 1) % opcoes.length
    else if (evento.key === "ArrowUp") this.indice = (this.indice - 1 + opcoes.length) % opcoes.length
    else if (evento.key === "Enter" && this.indice >= 0 && !this.listaTarget.hidden) {
      evento.preventDefault()
      return opcoes[this.indice].click()
    } else return

    evento.preventDefault()
    opcoes.forEach((opcao, posicao) => opcao.setAttribute("aria-selected", posicao === this.indice ? "true" : "false"))
    opcoes[this.indice].scrollIntoView({ block: "nearest" })
    this.textoTarget.setAttribute("aria-activedescendant", opcoes[this.indice].id)
  }

  fechar() {
    this.listaTarget.hidden = true
    this.textoTarget.setAttribute("aria-expanded", "false")
    this.textoTarget.removeAttribute("aria-activedescendant")
  }
}
