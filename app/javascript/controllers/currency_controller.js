import { Controller } from "@hotwired/stimulus"

// Máscara de moeda em reais, preenchendo da DIREITA para a esquerda.
//
//   digitar 1 1 9 9 0  ->  R$ 1,19 -> R$ 11,99 -> R$ 119,90
//
// O usuário nunca digita vírgula nem ponto: separador é consequência, não
// entrada. Dois campos trabalham juntos — o visível mostra a moeda formatada e
// o oculto carrega o decimal, para o Rails converter sem ambiguidade de
// separador.
export default class extends Controller {
  static targets = ["display", "value"]

  connect() {
    this.render(this.digitsFrom(this.valueTarget.value))
  }

  format() {
    this.render(this.displayTarget.value.replace(/\D/g, "").slice(0, 15))
  }

  // Converte o decimal que veio do servidor ("119.9") na sequência de dígitos
  // que a máscara usa ("11990").
  digitsFrom(decimal) {
    if (!decimal) return ""
    const cents = Math.round(Number.parseFloat(decimal) * 100)
    return Number.isFinite(cents) ? String(cents) : ""
  }

  render(digits) {
    const cents = Number.parseInt(digits || "0", 10)
    const amount = cents / 100

    this.displayTarget.value = amount.toLocaleString("pt-BR", {
      style: "currency",
      currency: "BRL"
    })
    this.valueTarget.value = amount.toFixed(2)
  }
}
