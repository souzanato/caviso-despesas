import { Controller } from "@hotwired/stimulus"

// Liga e desliga o modo de reordenação.
//
// A alça de arrasto não fica visível o tempo todo no celular: ela é um alvo a
// mais numa linha que já tem checkbox, nome, valor e categoria, e o gesto só
// interessa quando o usuário decide arrumar a ordem. Fora do modo, a linha fica
// limpa; dentro dele, a alça aparece.
const CLASS = "is-reordering"

export default class extends Controller {
  static targets = ["label"]

  connect() {
    this.list = document.getElementById("expense-list")
  }

  toggle() {
    if (!this.list) return

    const ativo = this.list.classList.toggle(CLASS)

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = ativo
        ? this.element.dataset.reorderModeDoneLabel
        : this.element.dataset.reorderModeStartLabel
    }

    // Ao entrar no modo, o foco vai para a primeira alça: quem acabou de pedir
    // para reordenar com o teclado não deve ter que caçar o primeiro controle.
    if (ativo) this.list.querySelector("[data-drag-handle]")?.focus()
  }
}
