import { Controller } from "@hotwired/stimulus"

// Abre e fecha o [modal] §8.
//
// Usa o <dialog> nativo: foco preso, fechamento por Escape e backdrop já vêm do
// navegador, e reimplementar isso à mão é onde os modais costumam quebrar
// acessibilidade.
export default class extends Controller {
  static targets = ["dialog"]

  // O modal alvo vem por parâmetro (`data-modal-id-param`), e não por alvo do
  // Stimulus: assim um mesmo controller serve aos dois modais da tela — o de
  // despesa e o de rubrica — sem duplicar controller nem aninhar escopo.
  open(event) {
    const dialog = this.dialogFor(event)
    if (!dialog) return

    dialog.showModal()

    // O primeiro campo recebe foco: quem abriu o modal já quer digitar.
    const first = dialog.querySelector("input:not([type=hidden]), select, textarea")
    if (first) first.focus()
  }

  dialogFor(event) {
    const id = event?.params?.id
    return id ? document.getElementById(id) : this.dialogTarget
  }

  // O modal a fechar é o que contém o gatilho — assim o mesmo controller
  // fecha qualquer um dos diálogos da tela sem saber qual é.
  close(event) {
    const dialog = event?.target?.closest("dialog") || this.dialogTarget
    dialog?.close()
  }

  // Descarte protegido: com algo digitado, tocar no fundo NÃO fecha — fechar
  // pelo fundo é hábito, mas em formulário preenchido ele perde dados. Vazio,
  // fecha direto.
  backdrop(event) {
    const dialog = event.currentTarget
    if (event.target !== dialog) return
    if (this.hasInput(dialog)) return
    dialog.close()
  }

  hasInput(dialog) {
    return [...dialog.querySelectorAll("input")].some(
      (input) => input.type !== "hidden" && input.value.trim() !== ""
    )
  }
}
