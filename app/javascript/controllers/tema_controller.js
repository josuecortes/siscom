import { Controller } from "@hotwired/stimulus"

// Alterna tema claro/escuro (porta de theme-toggle.tsx). O valor inicial é
// aplicado no <head> (layouts/compartilhado/_head) para evitar piscar.
export default class extends Controller {
  alternar() {
    const raiz = document.documentElement
    const proximo = raiz.dataset.theme === "dark" ? "light" : "dark"
    raiz.dataset.theme = proximo
    try { localStorage.setItem("siscom-tema", proximo) } catch (_) {}
  }
}
