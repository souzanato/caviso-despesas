import { Controller } from "@hotwired/stimulus"

// Envia o formulário assim que um controle muda.
//
// Usado no checkbox de "pago" da linha de despesa: a ação mais frequente do app
// não deve exigir um botão de salvar. O checkbox marca na hora (comportamento
// nativo do navegador), o envio acontece em seguida, e a resposta Turbo
// substitui a linha e o resumo.
//
// Handler inline (`onchange="..."`) faria o mesmo, mas seria bloqueado pela CSP.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
