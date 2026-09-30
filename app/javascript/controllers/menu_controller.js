import { Controller } from "@hotwired/stimulus"

// Ancora um popover no botão que o abriu.
//
// O `popover` nativo não sabe onde ficar: a folha do navegador o posiciona com
// `position: fixed; inset: 0; margin: auto`, e QUALQUER `margin` declarado por
// nós desfaz essa centralização — com `margin: 0` e `inset: 0` ele vai parar no
// canto superior esquerdo da janela.
//
// O CSS moderno resolve isso com `anchor-name`/`position-anchor`, mas o suporte
// ainda não é uniforme. Calcular no evento `toggle` são poucas linhas e vale em
// qualquer navegador.
const MARGEM = 4

export default class extends Controller {
  connect() {
    this.onToggle = (event) => {
      if (event.newState === "open") this.position()
    }

    this.element.addEventListener("toggle", this.onToggle)
  }

  disconnect() {
    this.element.removeEventListener("toggle", this.onToggle)
  }

  position() {
    // O botão se identifica pelo alvo que declara, então o controller não
    // precisa saber qual menu é este.
    const botao = document.querySelector(`[popovertarget="${this.element.id}"]`)
    if (!botao) return

    const r = botao.getBoundingClientRect()
    const estilo = this.element.style

    estilo.top = `${Math.round(r.bottom + MARGEM)}px`
    // Alinhado pela direita do botão — a convenção de menu de ações —, sem
    // encostar na borda da janela em telas estreitas.
    estilo.right = `${Math.round(Math.max(MARGEM, window.innerWidth - r.right))}px`
    estilo.left = "auto"
    estilo.bottom = "auto"
  }
}
