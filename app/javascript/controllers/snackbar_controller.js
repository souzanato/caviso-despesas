import { Controller } from "@hotwired/stimulus"

// Some sozinha depois de um tempo.
//
// O relógio para enquanto o foco ou o mouse estão em cima: quem está lendo a
// mensagem — ou indo clicar em "Desfazer" — não pode vê-la sumir debaixo da mão.
export default class extends Controller {
  static values = { duration: { type: Number, default: 8000 } }

  connect() {
    if (this.element.textContent.trim() === "") return
    this.schedule()
  }

  disconnect() {
    this.cancel()
  }

  schedule() {
    this.cancel()
    this.timer = setTimeout(() => this.clear(), this.durationValue)
  }

  cancel() {
    if (this.timer) clearTimeout(this.timer)
    this.timer = null
  }

  clear() {
    this.element.replaceChildren()
  }

  // Pausa enquanto o ponteiro ou o foco estão sobre a mensagem.
  hold() {
    this.cancel()
  }

  release() {
    this.schedule()
  }
}
