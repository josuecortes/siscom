// Service worker do Siscom (PWA).
// - Não guarda páginas do sistema em cache (são por usuário e mudam o tempo todo);
//   só a página "sem conexão", mostrada quando uma navegação falha.
// - Recebe notificações push e abre o sistema ao tocar nelas.
const CACHE = "siscom-v1"
const SEM_CONEXAO = "/sem-conexao.html"

self.addEventListener("install", (evento) => {
  evento.waitUntil(caches.open(CACHE).then((cache) => cache.addAll([SEM_CONEXAO, "/icone-192.png"])))
  self.skipWaiting()
})

self.addEventListener("activate", (evento) => {
  evento.waitUntil(
    caches.keys()
      .then((chaves) => Promise.all(chaves.filter((chave) => chave !== CACHE).map((chave) => caches.delete(chave))))
      .then(() => self.clients.claim())
  )
})

self.addEventListener("fetch", (evento) => {
  if (evento.request.mode !== "navigate") return

  evento.respondWith(fetch(evento.request).catch(() => caches.match(SEM_CONEXAO)))
})

self.addEventListener("push", (evento) => {
  let dados = {}
  try { dados = evento.data ? evento.data.json() : {} } catch (_) { dados = { titulo: evento.data.text() } }

  evento.waitUntil(
    self.registration.showNotification(dados.titulo || "Siscom", {
      body: dados.mensagem || "",
      icon: "/icone-192.png",
      badge: "/icone-192.png",
      tag: dados.tag,
      data: { url: dados.url || "/minha-area/notificacoes" }
    })
  )
})

self.addEventListener("notificationclick", (evento) => {
  evento.notification.close()
  const destino = new URL(evento.notification.data?.url || "/", self.location.origin)
  if (destino.origin !== self.location.origin) return

  evento.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((janelas) => {
      const aberta = janelas.find((janela) => new URL(janela.url).origin === destino.origin)
      if (aberta) return aberta.navigate(destino.href).then((janela) => janela && janela.focus())
      return self.clients.openWindow(destino.href)
    })
  )
})
