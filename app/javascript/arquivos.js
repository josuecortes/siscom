// Todo arquivo enviado ao sistema tem no máximo 1 MB (regra do sistema; o servidor confere de novo, em Anexo).
// Para a pessoa não esbarrar nisso com foto de celular:
// - imagem acima do limite é reduzida aqui mesmo (tamanho e qualidade) até caber, e vai como JPG;
// - documento (PDF etc.) acima do limite é recusado na hora, com o aviso embaixo do campo, antes de enviar.
// Vale para qualquer <input type="file"> do sistema, sem precisar marcar nada no campo.
const LIMITE = 1024 * 1024
const LADOS = [ 1920, 1600, 1280, 1024, 800 ]
const QUALIDADES = [ 0.85, 0.72, 0.6 ]
const REDUZIVEIS = [ "image/jpeg", "image/png", "image/webp" ]

const tamanho = (bytes) => bytes >= LIMITE ? `${(bytes / LIMITE).toFixed(1).replace(".", ",")} MB` : `${Math.max(1, Math.round(bytes / 1024))} KB`

function avisar(campo, texto, erro) {
  let aviso = campo.parentElement.querySelector("[data-arquivo-aviso]")
  if (!aviso) {
    aviso = document.createElement("p")
    aviso.dataset.arquivoAviso = "1"
    campo.after(aviso)
  }
  aviso.setAttribute("role", erro ? "alert" : "status")
  aviso.className = `mt-1.5 w-full basis-full text-sm ${erro ? "text-[var(--danger-text)]" : "text-[var(--text-secondary)]"}`
  aviso.textContent = texto
  aviso.hidden = !texto
}

function paraBlob(tela, qualidade) {
  return new Promise((resolve) => tela.toBlob(resolve, "image/jpeg", qualidade))
}

// Devolve a imagem em JPG dentro do limite, ou null se nem no menor tamanho coube (ou se não deu para ler).
async function reduzir(arquivo) {
  let imagem
  try {
    imagem = await createImageBitmap(arquivo)
  } catch {
    return null
  }
  for (const lado of LADOS) {
    const escala = Math.min(1, lado / Math.max(imagem.width, imagem.height))
    const tela = document.createElement("canvas")
    tela.width = Math.round(imagem.width * escala)
    tela.height = Math.round(imagem.height * escala)
    const pincel = tela.getContext("2d")
    pincel.fillStyle = "#ffffff" // PNG com transparência vira fundo branco no JPG
    pincel.fillRect(0, 0, tela.width, tela.height)
    pincel.drawImage(imagem, 0, 0, tela.width, tela.height)
    for (const qualidade of QUALIDADES) {
      const blob = await paraBlob(tela, qualidade)
      if (blob && blob.size <= LIMITE) return new File([ blob ], arquivo.name.replace(/\.[^.]+$/, "") + ".jpg", { type: "image/jpeg", lastModified: arquivo.lastModified })
    }
  }
  return null
}

async function conferir(campo) {
  const arquivos = [ ...campo.files ]
  if (arquivos.every((arquivo) => arquivo.size <= LIMITE)) return avisar(campo, "", false)

  const formulario = campo.form
  if (formulario) formulario.dataset.arquivosEmPreparo = String(Number(formulario.dataset.arquivosEmPreparo || 0) + 1)
  avisar(campo, "Preparando o arquivo…", false)
  try {
    const prontos = new DataTransfer()
    const reduzidos = []
    for (const arquivo of arquivos) {
      if (arquivo.size <= LIMITE) {
        prontos.items.add(arquivo)
        continue
      }
      const menor = REDUZIVEIS.includes(arquivo.type) ? await reduzir(arquivo) : null
      if (!menor) {
        campo.value = "" // nada vai: a pessoa escolhe de novo
        campo.dispatchEvent(new CustomEvent("siscom:arquivo-recusado", { bubbles: true }))
        return avisar(campo, `"${arquivo.name}" tem ${tamanho(arquivo.size)}. O limite é 1 MB por arquivo: reduza o arquivo (ou divida o documento) e escolha de novo.`, true)
      }
      prontos.items.add(menor)
      reduzidos.push(`${arquivo.name}: de ${tamanho(arquivo.size)} para ${tamanho(menor.size)}`)
    }
    campo.files = prontos.files
    avisar(campo, `Imagem reduzida para caber em 1 MB (${reduzidos.join("; ")}).`, false)
  } finally {
    if (formulario) formulario.dataset.arquivosEmPreparo = String(Math.max(0, Number(formulario.dataset.arquivosEmPreparo || 1) - 1))
  }
}

document.addEventListener("change", (evento) => {
  if (evento.target instanceof HTMLInputElement && evento.target.type === "file") conferir(evento.target)
})

// Enquanto uma imagem está sendo reduzida, o formulário espera (senão iria o arquivo grande).
document.addEventListener("submit", (evento) => {
  if (Number(evento.target.dataset?.arquivosEmPreparo || 0) > 0) {
    evento.preventDefault()
    evento.stopImmediatePropagation()
  }
}, true)
