import { Controller } from "@hotwired/stimulus"

// Mantém a página parada quando o Turbo Stream substitui uma linha.
//
// Marcar pago troca a `<li>` inteira, e isso destrói o checkbox que estava com
// foco. O navegador então reposiciona a rolagem — o usuário perde o lugar na
// lista, e quem navega por teclado perde o foco a cada marcação.
//
// Guarda a rolagem e o id do elemento focado antes do envio, e devolve os dois
// depois. `preventScroll` no foco é essencial: focar sem ele faria o navegador
// rolar até o elemento, anulando a restauração.
export default class extends Controller {
  connect() {
    this.save = () => {
      this.scroll = window.scrollY
      this.focusId = document.activeElement?.id
    }

    this.restore = () => {
      // Um quadro depois: o Turbo aplica os streams e só então o DOM está no
      // estado final.
      requestAnimationFrame(() => {
        if (this.scroll !== undefined) window.scrollTo(0, this.scroll)

        if (this.focusId) {
          document.getElementById(this.focusId)?.focus({ preventScroll: true })
        }
      })
    }

    this.element.addEventListener("turbo:submit-start", this.save)
    this.element.addEventListener("turbo:submit-end", this.restore)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this.save)
    this.element.removeEventListener("turbo:submit-end", this.restore)
  }
}
