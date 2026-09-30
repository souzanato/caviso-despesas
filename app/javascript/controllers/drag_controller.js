import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Reordenação das despesas de uma rubrica.
//
// Dois caminhos para a MESMA ação, e é de propósito: arrastar (mouse e toque,
// via SortableJS) e as setas ↑/↓ na alça focada. Arrastar não é alcançável por
// teclado, e sem o segundo caminho a função ficaria indisponível para quem não
// usa mouse — o §7 exige os dois.
//
// A ordem é gravada ao soltar. Não há botão de salvar: a posição é o dado.
export default class extends Controller {
  static targets = ["list", "status"]
  static values = { url: String }

  connect() {
    // Sem lista não há o que arrastar (estado vazio) — o controller fica no
    // wrapper para a região viva ser irmã da <ul>, e não filha.
    if (!this.hasListTarget) return

    this.sortable = Sortable.create(this.listTarget, {
      handle: "[data-drag-handle]",
      animation: 150,
      // Nomes próprios em vez das classes padrão do SortableJS, para o estilo
      // ficar junto dos outros componentes na folha do Design System.
      ghostClass: "ds-expense-row--ghost",
      chosenClass: "ds-expense-row--drag",
      // A linha não pode ser arrastada pelo corpo: ele abre a edição.
      draggable: "[data-drag-item]",
      onEnd: () => this.persist()
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  // Setas movem uma posição. Nos extremos, o movimento é ignorado sem erro.
  move(event) {
    const passo = { ArrowUp: -1, ArrowDown: 1 }[event.key]
    if (passo === undefined) return

    event.preventDefault()

    const linhas = [...this.listTarget.querySelectorAll("[data-drag-item]")]
    const linha = event.currentTarget.closest("[data-drag-item]")
    const atual = linhas.indexOf(linha)
    const destino = atual + passo

    if (destino < 0 || destino >= linhas.length) return

    if (passo < 0) {
      this.listTarget.insertBefore(linha, linhas[destino])
    } else {
      this.listTarget.insertBefore(linhas[destino], linha)
    }

    this.announce(linha, destino + 1, linhas.length)
    this.persist()
  }

  announce(linha, posicao, total) {
    if (!this.hasStatusTarget) return

    const nome = linha.querySelector(".ds-expense-row__name")?.textContent.trim()
    this.statusTarget.textContent = `${nome}, posição ${posicao} de ${total}`
  }

  // Envia o estado FINAL (a lista de ids na ordem nova), não uma sequência de
  // passos. O servidor não devolve corpo: a ordem já está na tela.
  persist() {
    const ids = [...this.listTarget.querySelectorAll("[data-drag-item]")].map(
      (linha) => linha.dataset.dragItem
    )

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ ids })
    })
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
