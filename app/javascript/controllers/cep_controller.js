import { Controller } from "@hotwired/stimulus"

// Endereço pelo CEP: ao completar os 8 dígitos, busca o endereço no servidor e preenche
// rua, bairro, cidade e UF; depois é só informar o número. Se o CEP não for encontrado,
// os campos ficam livres para digitar.
export default class extends Controller {
  static targets = ["cep", "logradouro", "bairro", "cidade", "uf", "numero", "situacao"]
  static values = { url: String }

  digitar() {
    const digitos = this.cepTarget.value.replace(/\D/g, "").slice(0, 8)
    this.cepTarget.value = digitos.length > 5 ? `${digitos.slice(0, 5)}-${digitos.slice(5)}` : digitos
    if (digitos.length === 8 && digitos !== this.ultimo) this.buscar(digitos)
    if (digitos.length < 8) this.avisar("")
  }

  async buscar(digitos) {
    this.ultimo = digitos
    this.avisar("Procurando o CEP…")
    try {
      const resposta = await fetch(this.urlValue.replace("00000000", digitos), { headers: { Accept: "application/json" } })
      const dados = await resposta.json()
      if (!resposta.ok) return this.avisar(dados.erro || "CEP não encontrado.", true)

      this.logradouroTarget.value = dados.logradouro || ""
      this.bairroTarget.value = dados.bairro || ""
      this.cidadeTarget.value = dados.cidade || ""
      this.ufTarget.value = dados.uf || ""
      this.avisar("Endereço preenchido pelo CEP. Informe o número.")
      this.numeroTarget.focus()
      this.dispatch("preenchido") // quem tiver um mapa junto (controller `mapa`) pode ir até o endereço
    } catch (_) {
      this.avisar("Não foi possível consultar o CEP agora. Preencha o endereço à mão.", true)
    }
  }

  avisar(texto, erro = false) {
    this.situacaoTarget.textContent = texto
    this.situacaoTarget.classList.toggle("text-[var(--danger-text)]", erro)
    this.situacaoTarget.classList.toggle("text-[var(--text-muted)]", !erro)
  }
}
