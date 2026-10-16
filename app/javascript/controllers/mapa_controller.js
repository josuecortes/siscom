import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Campo de endereço com mapa (porta de transport-map-picker.tsx). Clicar no mapa marca o ponto e
// preenche o endereço (o servidor consulta o OpenStreetMap); preencher o endereço e chamar
// `localizar` leva o mapa até lá. As imagens do mapa vêm pelo próprio servidor.
//   data-controller="mapa" data-mapa-tiles-value="/mapa/tiles/{z}/{x}/{y}"
//   data-mapa-reverso-value="/mapa/reverso" data-mapa-busca-value="/mapa/buscar"
export default class extends Controller {
  static targets = ["quadro", "latitude", "longitude", "cep", "logradouro", "numero", "bairro", "cidade", "uf", "situacao"]
  static values = { tiles: String, reverso: String, busca: String, centro: { type: Array, default: [0.04603, -51.06929] } } // Macapá

  connect() {
    const ponto = this.ponto()
    // Zoom inicial do seed: 17 no centro de Macapá, 15 quando o destino já tem ponto.
    this.mapa = L.map(this.quadroTarget, { scrollWheelZoom: true }).setView(ponto || this.centroValue, ponto ? 15 : 17)
    L.tileLayer(this.tilesValue, { maxZoom: 19, attribution: "© OpenStreetMap" }).addTo(this.mapa)
    this.mapa.on("click", (evento) => this.escolher(evento.latlng.lat, evento.latlng.lng))
    if (ponto) this.marcar(...ponto)
    // Dentro de painel ou item recém-adicionado, o mapa só conhece o próprio tamanho depois de aparecer.
    this.ajuste = setTimeout(() => this.mapa.invalidateSize(), 150)
  }

  disconnect() {
    clearTimeout(this.ajuste)
    this.mapa?.remove()
  }

  ponto() {
    const lat = parseFloat(this.latitudeTarget.value), lon = parseFloat(this.longitudeTarget.value)
    return Number.isFinite(lat) && Number.isFinite(lon) ? [lat, lon] : null
  }

  marcar(lat, lon) {
    this.latitudeTarget.value = lat.toFixed(6)
    this.longitudeTarget.value = lon.toFixed(6)
    if (this.marcador) this.marcador.setLatLng([lat, lon])
    else this.marcador = L.circleMarker([lat, lon], { radius: 8, weight: 2, fillOpacity: 0.6 }).addTo(this.mapa)
  }

  // Clique no mapa: marca o ponto e pede o endereço dele.
  async escolher(lat, lon) {
    this.marcar(lat, lon)
    this.avisar("Procurando o endereço deste ponto…")
    const dados = await this.pedir(`${this.reversoValue}?lat=${lat.toFixed(6)}&lon=${lon.toFixed(6)}`)
    if (!dados?.endereco) return this.avisar(dados?.erro || "Não achei um endereço para este ponto. Preencha à mão.", true)

    const endereco = dados.endereco
    for (const campo of ["cep", "logradouro", "bairro", "cidade", "uf"]) {
      if (endereco[campo] && this[`has${campo[0].toUpperCase()}${campo.slice(1)}Target`]) this[`${campo}Target`].value = endereco[campo]
    }
    this.avisar("Endereço preenchido pelo mapa. Confira e informe o número.")
  }

  // Endereço digitado (ou vindo do CEP): leva o mapa até ele.
  async localizar() {
    const partes = ["logradouro", "numero", "bairro", "cidade", "uf"].map((campo) => this[`${campo}Target`].value.trim())
    if (!partes[0] || !partes[3]) return
    const texto = partes.filter(Boolean).join(", ")
    if (texto === this.ultimaBusca) return
    this.ultimaBusca = texto

    const dados = await this.pedir(`${this.buscaValue}?q=${encodeURIComponent(texto)}`)
    const lugar = dados?.lugares?.[0]
    if (!lugar) return this.avisar("Não achei este endereço no mapa. Se quiser, clique no mapa para marcar o ponto.")

    this.marcar(lugar.latitude, lugar.longitude)
    this.mapa.setView([lugar.latitude, lugar.longitude], 16)
    this.avisar("Ponto marcado no mapa. Clique em outro lugar para ajustar.")
  }

  async pedir(url) {
    try {
      const resposta = await fetch(url, { headers: { Accept: "application/json" } })
      return await resposta.json()
    } catch (_) {
      return { erro: "Não foi possível consultar o mapa agora. Preencha o endereço à mão." }
    }
  }

  avisar(texto, erro = false) {
    if (!this.hasSituacaoTarget) return
    this.situacaoTarget.textContent = texto
    this.situacaoTarget.classList.toggle("text-[var(--danger-text)]", erro)
  }
}
