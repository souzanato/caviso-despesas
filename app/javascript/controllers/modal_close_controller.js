import { Controller } from "@hotwired/stimulus"

// Fecha um <dialog> assim que este elemento entra no DOM.
//
// Existe para o retorno de uma criação bem-sucedida: o servidor responde com
// Turbo Stream, e "fechar o modal" é efeito no cliente. O elemento se remove
// depois, para não ficar sobrando no DOM a cada criação.
export default class extends Controller {
  static values = { targetId: String }

  connect() {
    document.getElementById(this.targetIdValue)?.close()
    this.element.remove()
  }
}
