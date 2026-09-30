import { Controller } from "@hotwired/stimulus"

// [rubrica-picker] §7: folha sobreposta no celular, coluna permanente no
// desktop. É o MESMO markup e o MESMO controller — quem decide qual das duas
// apresentações está valendo é a largura.
//
// No DESKTOP a coluna já está sempre visível, então o título deixa de ser um
// controle. Sem desativá-lo, ele continuaria focável por teclado e anunciado
// como um botão que abre algo que já está aberto.
const DESKTOP = "(min-width: 992px)"

// Rede de segurança para o atributo faltar. O número de verdade vive no markup
// (`data-picker-limit-value`, em home/index.html.erb) — é decisão de produto, e
// quem a toma lê a tela, não o controller.
const LIMITE_PADRAO = 12

// Classe que trava a rolagem do <body> enquanto a folha está aberta. Vive no
// body porque é ele quem rola.
const TRAVA = "ds-sheet-open"

export default class extends Controller {
  static targets = ["toggle", "panel", "backdrop", "body", "search", "clear", "option", "empty", "more"]
  static values = { label: String, limit: Number }

  connect() {
    this.media = window.matchMedia(DESKTOP)
    this.onChange = () => this.syncToggle()
    this.onKeydown = (event) => {
      if (event.key === "Escape") this.close()
    }
    this.onBeforeCache = () => this.destravar()

    this.media.addEventListener("change", this.onChange)
    document.addEventListener("keydown", this.onKeydown)
    document.addEventListener("turbo:before-cache", this.onBeforeCache)

    // Estado de abertura não sobrevive a uma navegação: o Turbo guarda o
    // <body> no cache da página, e a classe de trava iria junto — a tela
    // seguinte nasceria sem rolagem.
    this.destravar()
    this.expandido = false

    this.syncToggle()
    this.revealSelected()
  }

  disconnect() {
    this.media.removeEventListener("change", this.onChange)
    document.removeEventListener("keydown", this.onKeydown)
    document.removeEventListener("turbo:before-cache", this.onBeforeCache)
    this.destravar()
  }

  get aberto() {
    return !this.panelTarget.hidden
  }

  get desktop() {
    return this.media.matches
  }

  get limite() {
    return this.limitValue || LIMITE_PADRAO
  }

  toggle() {
    if (this.aberto) this.close()
    else this.open()
  }

  open() {
    if (this.desktop) return

    this.panelTarget.hidden = false
    this.backdropTarget.hidden = false
    this.travarm()
    this.toggleTarget.setAttribute("aria-expanded", "true")

    // A folha é modal: só aqui ela é um diálogo. No desktop, o mesmo elemento
    // é a coluna de navegação, e anunciá-la como diálogo seria mentir para o
    // leitor de tela.
    this.panelTarget.setAttribute("role", "dialog")
    this.panelTarget.setAttribute("aria-label", this.labelValue)

    // Abrir é sempre começar pelo recorte, mesmo que a vez anterior tenha
    // terminado expandida.
    this.expandido = false
    this.aplicarLista()
    this.revealSelected()
    this.focusAtiva()
  }

  close() {
    // No desktop não há o que fechar — a coluna não é modal.
    if (this.desktop || !this.aberto) return

    this.panelTarget.hidden = true
    this.backdropTarget.hidden = true
    this.destravar()
    this.toggleTarget.setAttribute("aria-expanded", "false")

    // O foco volta para quem abriu. Sem isto ele fica num elemento que acabou
    // de sair da tela, e o próximo Tab começa do topo do documento.
    this.toggleTarget.focus({ preventScroll: true })
  }

  // "Ver todas (N)": o resto da lista, rolando dentro da própria folha.
  showAll() {
    this.expandido = true
    this.aplicarLista()
    this.revealSelected()
  }

  // O campo é `type="search"`, mas o painel não é um formulário: Enter não tem
  // destino para onde enviar. Com UM resultado só, ele é a resposta inteira —
  // obrigar a tirar a mão do teclado e tocar na linha seria um passo a mais para
  // chegar no único lugar possível.
  submit(event) {
    event.preventDefault()

    const visiveis = this.optionTargets.filter((item) => !item.hidden)
    if (visiveis.length !== 1) return

    visiveis[0].querySelector(".ds-picker__item")?.click()
  }

  filter() {
    this.aplicarLista()
  }

  clear() {
    this.searchTarget.value = ""
    this.aplicarLista()

    // O foco volta para o campo: o "×" acaba de ser tocado e, sem isto, ele
    // ficaria num botão que some no mesmo instante — o foco cairia no <body> e
    // o próximo Tab recomeçaria do topo do documento.
    this.searchTarget.focus({ preventScroll: true })
  }

  // Reconcilia a lista com o estado — termo de busca, expansão e rubrica
  // aberta.
  //
  // Uma função só porque as três coisas disputam a MESMA decisão (quem
  // aparece) e espalhá-las por três métodos produzia combinações que ninguém
  // tinha testado, como filtrar depois de expandir.
  aplicarLista() {
    const termo = this.hasSearchTarget ? this.normalize(this.searchTarget.value) : ""
    const filtrando = termo !== ""
    const recentes = this.limite

    // Com a busca preenchida o recorte não vale: quem digita quer ACHAR, e um
    // resultado escondido é pior que uma lista longa — inclusive quando ele
    // está fora das recentes.
    const recorte = filtrando || this.expandido ? null : recentes
    const ativa = this.optionTargets.findIndex((item) => item.querySelector(".is-active"))

    let visiveis = 0

    this.optionTargets.forEach((item, indice) => {
      const casa = !filtrando || this.normalize(item.dataset.pickerName).includes(termo)
      // A rubrica aberta nunca sai do recorte: ela é a referência de onde o
      // usuário está, e escondê-la obrigaria a procurar o que já se sabe.
      const noRecorte = recorte === null || indice < recorte || indice === ativa
      // Se ela estiver fora das recentes, entra no lugar da última — a lista
      // continua com o mesmo tamanho.
      const empurrada = recorte !== null && indice === recorte - 1 && ativa >= recorte

      item.hidden = !casa || !noRecorte || empurrada
      if (!item.hidden) visiveis += 1
    })

    this.moreTarget.hidden = recorte === null || this.optionTargets.length <= recentes
    this.emptyTarget.hidden = visiveis > 0

    if (this.hasClearTarget) this.clearTarget.hidden = this.searchTarget.value === ""
  }

  // Busca tolerante a acentos: "sao paulo" encontra "São Paulo". A MESMA regra
  // do [combobox] (§5) — duas normalizações diferentes na mesma aplicação
  // produziriam buscas que ora acham, ora não, sem o usuário entender por quê.
  normalize(value) {
    return (value || "")
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "")
      .toLowerCase()
      .trim()
  }

  // Rola a lista até a rubrica selecionada.
  //
  // No desktop a coluna já está aberta e a lista costuma caber; no celular a
  // folha tem teto e rola. Sem rolar, a rubrica aberta pode estar fora da vista
  // numa lista de 20, e o usuário não descobre onde está sem procurar.
  revealSelected() {
    const corpo = this.bodyTarget
    const atual = this.panelTarget.querySelector(".ds-picker__item.is-active")
    if (!corpo || !atual) return
    if (corpo.scrollHeight <= corpo.clientHeight) return

    // A posição é medida RELATIVA AO CORPO, e não por `offsetTop`.
    //
    // `offsetTop` é medido a partir do `offsetParent` — o ancestral posicionado
    // mais próximo (`.ds-ledger-pinned` é `sticky`) — e não do contêiner que
    // rola. Os dois diferem por um deslocamento fixo, e era ele que jogava o
    // cálculo para o fim da lista, escondendo justamente a rubrica selecionada.
    //
    // `scrollTop` no corpo, e NÃO `scrollIntoView`: aquele sobe por todos os
    // ancestrais roláveis e rolava a PÁGINA inteira.
    const deslocamento = atual.getBoundingClientRect().top - corpo.getBoundingClientRect().top
    const topo = deslocamento + corpo.scrollTop
    corpo.scrollTop = topo - (corpo.clientHeight - atual.offsetHeight) / 2
  }

  focusAtiva() {
    const atual = this.panelTarget.querySelector(".ds-picker__item.is-active")
    // `preventScroll`: quem posiciona a lista é o `revealSelected`, com o
    // cálculo certo. Deixar o navegador rolar junto brigaria com ele — e ele
    // rolaria a página, não a folha.
    atual?.focus({ preventScroll: true })
  }

  travarm() {
    document.body.classList.add(TRAVA)
  }

  destravar() {
    document.body.classList.remove(TRAVA)
  }

  // Reconcilia o controle com a largura atual — roda no boot e a cada
  // travessia do breakpoint, então arrastar a janela entre os dois modos não
  // deixa o painel num estado que não corresponde ao que está na tela.
  syncToggle() {
    const desktop = this.desktop

    this.toggleTarget.disabled = desktop
    this.toggleTarget.tabIndex = desktop ? -1 : 0

    if (desktop) {
      this.toggleTarget.removeAttribute("aria-expanded")
      this.panelTarget.removeAttribute("role")
      this.panelTarget.removeAttribute("aria-label")
      this.panelTarget.hidden = false
      this.backdropTarget.hidden = true
      this.destravar()
      // A coluna É a lista completa: sem recorte e sem "Ver todas".
      this.expandido = true
    } else {
      this.toggleTarget.setAttribute("aria-expanded", String(!this.panelTarget.hidden))
      this.expandido = false
    }

    this.aplicarLista()
  }
}
