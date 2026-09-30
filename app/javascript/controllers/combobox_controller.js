import { Controller } from "@hotwired/stimulus"

// Campo com busca e criação na hora.
//
// A lista já vem renderizada com todas as categorias; filtrar é esconder o que
// não casa. Quando o texto digitado não corresponde exatamente a nenhuma opção,
// aparece "Criar "…"" como última linha — e o valor enviado é o NOME, então o
// servidor resolve os dois casos com a mesma regra.
export default class extends Controller {
  static targets = ["input", "value", "list", "option", "create"]

  open() {
    this.listTarget.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
    this.filter()
  }

  close() {
    this.listTarget.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
  }

  filter() {
    const term = this.normalize(this.inputTarget.value)
    let visible = 0

    this.optionTargets.forEach((option) => {
      const matches = this.normalize(option.dataset.comboboxName).includes(term)
      option.hidden = !matches
      if (matches) visible += 1
    })

    const exact = this.optionTargets.some(
      (option) => this.normalize(option.dataset.comboboxName) === term
    )

    // Sem correspondência exata e com algo digitado: oferece criar.
    const canCreate = term !== "" && !exact
    this.createTarget.hidden = !canCreate

    if (canCreate) {
      this.createTarget.querySelector("button").textContent =
        `Criar "${this.inputTarget.value.trim()}"`
    }
  }

  select(event) {
    // O nome vive no <li> (o alvo `option`), não no <button> que recebe o
    // clique. Ler de `currentTarget` devolvia `undefined` e gravava a string
    // "undefined" como nome da categoria.
    const option = event.currentTarget.closest('[data-combobox-target="option"]')
    const name = option?.dataset.comboboxName
    if (!name) return

    this.inputTarget.value = name
    // O campo visível é quem carrega o valor. O alvo `value` só existe se
    // houver um campo oculto espelhando — deixou de ser o caso, mas o
    // controller continua aceitando os dois.
    if (this.hasValueTarget) this.valueTarget.value = name
    this.close()
  }

  create() {
    if (this.hasValueTarget) this.valueTarget.value = this.inputTarget.value.trim()
    this.close()
  }

  // Busca tolerante a acentos: "comunicacao" encontra "Comunicação".
  normalize(value) {
    return (value || "")
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "")
      .toLowerCase()
      .trim()
  }
}
