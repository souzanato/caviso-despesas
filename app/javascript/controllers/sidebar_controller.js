import { Controller } from "@hotwired/stimulus"
import { Offcanvas } from "bootstrap"

// Estado da sidebar.
//
// Desktop (>= lg): expandida ou retraída, com a preferência guardada no
// localStorage. A largura em si é CSS — aqui só alternamos a classe que troca
// a custom property do grid.
//
// Mobile (< lg): a sidebar é um offcanvas do Bootstrap. Abrir, backdrop,
// Escape e trava de scroll ficam por conta do Bootstrap (data-bs-toggle);
// aqui só implementamos o FECHAR, porque o Bootstrap 5.3 não trata
// `data-bs-dismiss="offcanvas"` (não há handler para isso no bundle dele).
const COLLAPSED_CLASS = "is-sidebar-collapsed"
const STORAGE_KEY = "despesas:app-sidebar"

export default class extends Controller {
  static targets = ["toggle", "drawer"]

  connect() {
    this.collapsed = this.readStoredCollapsed()
    this.render()
  }

  toggle() {
    this.apply(!this.collapsed)
  }

  // Um item de menu com submenu é clicado com a sidebar retraída: reexpande
  // para que o submenu (que fica oculto no estado retraído) possa aparecer.
  expand() {
    if (this.collapsed) this.apply(false)
  }

  // Chamado pelo botão de fechar dentro do drawer.
  close() {
    const instance = this.hasDrawerTarget && Offcanvas.getInstance(this.drawerTarget)
    if (instance) instance.hide()
  }

  apply(collapsed) {
    this.collapsed = collapsed

    try {
      window.localStorage.setItem(STORAGE_KEY, collapsed ? "collapsed" : "expanded")
    } catch (error) {
      // localStorage bloqueado (ex.: modo privado): segue só em memória.
    }

    this.render()
  }

  // O padrão é ENCOLHIDA. O servidor já renderiza a classe (ver
  // application.html.erb) para não haver piscada de "abre e fecha" no primeiro
  // paint; aqui só reconciliamos com a preferência que o usuário tenha salvo.
  readStoredCollapsed() {
    try {
      const stored = window.localStorage.getItem(STORAGE_KEY)
      return stored === null ? true : stored === "collapsed"
    } catch (error) {
      return true
    }
  }

  render() {
    this.element.classList.toggle(COLLAPSED_CLASS, this.collapsed)

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", String(!this.collapsed))
    }
  }
}
