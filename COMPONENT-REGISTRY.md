# COMPONENT-REGISTRY.md

> **Registro técnico de implementação da UI.**
>
> Este arquivo responde exclusivamente: **o que já está implementado e onde está?**
>
> As regras visuais não vivem aqui. A aparência, composição, variantes, estados e responsividade pertencem ao `DESIGN-SYSTEM.md`.

---

## 1. Regras do registro

- Um item com `status: implemented` deve apontar para os arquivos reais que materializam a especificação correspondente do `DESIGN-SYSTEM.md`.
- Antes de criar um novo componente, o Claude Code deve consultar este arquivo e também pesquisar o projeto por implementações equivalentes para evitar duplicação.
- `not_implemented` significa que existe especificação no Design System, mas ainda não há implementação confirmada no código.
- `partial` significa que existe implementação incompleta ou ainda não aderente a toda a especificação.
- `deprecated` significa que a implementação não deve ser usada em código novo.
- Alterar código de UI exige atualizar este registro quando o estado, os arquivos ou a observação técnica mudarem.
- Implementar uma nova view que apenas **consome** um componente existente não exige listar todas as views consumidoras aqui.

### Convenções de caminho

- Estilos compartilhados de shell: `app/assets/stylesheets/app_shell.scss`
- Estilos das telas de Devise: `app/assets/stylesheets/devise_auth.scss`
- Foundations: `app/assets/stylesheets/design_system/_tokens.scss`
- Não existem mais `app/views/shared/` nem `app/assets/stylesheets/design_system/components/`.
  Um componente é registrado pelos arquivos que realmente o materializam, ainda que
  compartilhe arquivo de estilo com outros (ver `implementation_notes`).

---

## 2. Formato

```md
### [component-name]
- status: not_implemented | partial | implemented | deprecated
- files:
  - view: caminho/se/aplicável
  - style: caminho/se/aplicável
  - javascript: caminho/se/aplicável
  - helper: caminho/se/aplicável
  - test: caminho/se/aplicável
- implementation_notes: observações estritamente técnicas
- last_verified: AAAA-MM-DD | unknown
```

Para telas:

```md
### [screen-name]
- status: not_implemented | partial | implemented | deprecated
- files:
  - view: caminho da view
  - style: caminho específico, se existir
  - javascript: caminho específico, se existir
- implementation_notes: observações técnicas
- last_verified: AAAA-MM-DD | unknown
```

---

# 3. Foundations

### [color-tokens]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_tokens.scss`
  - style: `app/assets/stylesheets/design_system/_theme_app.scss`
  - style: `app/assets/stylesheets/design_system/_theme_auth.scss`
  - style: `app/assets/stylesheets/_palette.scss`
- implementation_notes: `_palette.scss` guarda os hex crus (única camada onde hex é permitido). `_tokens.scss` converte em fundamentos **compartilhados** (marca, semânticas de preenchimento, variantes suaves). `_theme_app.scss` define em `:root` os tokens de **contexto light** (área autenticada, padrão). `_theme_auth.scss` define os mesmos nomes de contexto com valores **dark**, escopados em `html:has(.auth-shell)` — a especificidade (0,1,1) vence o `:root` (0,1,0) independentemente da ordem das folhas, o que também impede vazamento se o bundle de autenticação continuar carregado após navegação Turbo. Não há troca de tema em tempo de execução nem dependência de `data-theme`.
- last_verified: 2026-09-28

### [typography-tokens]
- status: not_implemented
- files: []
- implementation_notes: a especificação do §4 lista as categorias (`display`, `h1`, `h2`, `h3`, `body`, `body-secondary`, `caption`, `money`) mas não define tamanho, peso ou line-height para nenhuma delas. Implementar exigiria inventar valores, o que a Rule 8 proíbe. Os tamanhos atuais seguem literais por componente.
- last_verified: 2026-09-28

### [spacing-tokens]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_tokens.scss`
- implementation_notes: escala `--space-1..--space-16` (4/8/12/16/24/32/48/64). Shell e telas de Devise consomem a mesma escala. Permanecem literais fora de escala apenas em geometria de componente (largura/altura de ícone, tamanho de checkbox, offsets de animação).
- last_verified: 2026-09-28

### [radius-tokens]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_tokens.scss`
- implementation_notes: `--radius-sm|md|lg|pill` conforme §4. Substituíram valores arbitrários anteriores (10px, 18px, 20px).
- last_verified: 2026-09-28

### [elevation-tokens]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_theme_app.scss`
  - style: `app/assets/stylesheets/design_system/_theme_auth.scss`
- implementation_notes: `--elevation-1` e `--elevation-2` são tokens de contexto, porque sombra é justamente o que difere entre claro e escuro: no light ela separa camadas (valores contidos), no dark a separação vem de camada e borda. `--elevation-2` é a mesma sombra para dropdown do shell e card de autenticação — dentro de cada contexto.
- last_verified: 2026-09-28

---

# 4. Componentes de formulário

### [button]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - view: `app/views/categories/index.html.erb`
  - view: `app/views/categories/_form.html.erb`
  - view: `app/views/devise/sessions/new.html.erb`
- implementation_notes: `.ds-btn`, compartilhado pelos dois contextos — um componente, valores vindos dos tokens de contexto. Variantes `--primary`, `--secondary`, `--danger` (§5) e as contextuais `--oauth` / `--passkey`; modificadores `--block` e `--compact`. Antes vivia só como `.auth-btn`, escopado ao Devise; foi promovido para não existir um botão paralelo na área autenticada. `default` tem 48px (valor que a autenticação já usava) e `compact` 44px.
- last_verified: 2026-09-29

### [input-text]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - view: `app/views/categories/_form.html.erb`
- implementation_notes: `.ds-field` (+ `__label`, `__input`, `__hint`), compartilhado pelos dois contextos. Antes era `.auth-field`, escopado ao Devise. Estados `disabled` e `error` no próprio campo continuam não implementados — o erro é comunicado pelo bloco `[error-message]`, como o §5 permite.
- last_verified: 2026-09-29

### [combobox]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - javascript: `app/javascript/controllers/combobox_controller.js`
  - view: `app/views/ledger_items/_form.html.erb`
- implementation_notes: Busca tolerante a acentos e opcao `Criar "..."` quando nao ha correspondencia exata. O valor enviado e o NOME da categoria, nao o id: o servidor resolve escolher-uma-existente e criar-uma-nova com a mesma regra.
- last_verified: 2026-09-29

---

### [input-currency]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - javascript: `app/javascript/controllers/currency_controller.js`
  - view: `app/views/ledger_items/_form.html.erb`
- implementation_notes: Mascara de reais preenchendo da direita para a esquerda. Dois campos: o visivel mostra a moeda formatada, o oculto carrega o decimal — evita ambiguidade de separador na conversao do Rails.
- last_verified: 2026-09-29

### [checkbox-toggle]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - view: `app/views/devise/sessions/new.html.erb`
  - view: `app/views/ledgers/_form.html.erb`
- implementation_notes: `.ds-choice`, promovido do bundle de autenticacao nesta tarefa junto com [button] e [input-text] — o modal de rubrica precisa dele, e manter uma copia so no auth seria implementacao paralela (Rule 5). O modo toggle para preferencias persistentes continua nao implementado.
- last_verified: 2026-09-29

### [error-message]
- status: implemented
- files:
  - view: `app/views/shared/_error_messages.html.erb`
  - view: `app/views/shared/_flash.html.erb`
  - style: `app/assets/stylesheets/design_system/_components.scss`
- implementation_notes: `.ds-alert--error` usa `--color-danger-text` sobre `--color-danger-bg` (fundo de baixa intensidade), com ícone + lista textual de mensagens e `radius-md`. A variante `--notice` serve o flash. Antes era `.auth-alert`, escopado ao Devise, com o parcial em `devise/shared/`; foi promovido a componente compartilhado e os parciais movidos para `shared/`, parametrizando o título do bloco de erros (`title_key`) para preservar a copy de cada contexto. O flash agora também é renderizado no layout da aplicação, que não tinha região de flash.
- last_verified: 2026-09-29

---

# 5. Navegação e estrutura

### [app-shell]
- status: implemented
- files:
  - view: `app/views/layouts/application.html.erb`
  - view: `app/views/layouts/_head.html.erb`
  - style: `app/assets/stylesheets/app_shell.scss`
- implementation_notes: grid CSS de 4 áreas (`topbar`/`sidebar`/`main`/`footer`) em `dvh`. Topbar e rodapé atravessam a largura; a coluna da sidebar só existe a partir de 992px. O conteúdo desktop é centralizado com `max-width: 1280px`. O estado de retração é uma classe (`.is-sidebar-collapsed`) na raiz do shell. Tema **light**, que é o padrão desta área: superfícies brancas sobre fundo off-white, separadas por borda de 1px. O fundo do `<body>` **não** é declarado aqui — cada contexto declara a sua base em seu próprio tema.
- last_verified: 2026-09-28

### [top-navbar]
- status: implemented
- files:
  - view: `app/views/layouts/_topbar.html.erb`
  - view: `app/views/layouts/_user_menu.html.erb`
  - style: `app/assets/stylesheets/app_shell.scss`
- implementation_notes: `position: sticky` com `--app-topbar-h: 56px`. Hospeda dois `[icon-button]` mutuamente exclusivos por breakpoint (`d-lg-none` abre o drawer, `d-none d-lg-inline-flex` retrai a sidebar) e o brand. O nome do usuário não é exibido ao lado do avatar — apenas o avatar, em todos os breakpoints.
- last_verified: 2026-09-28

### [icon-button]
- status: implemented
- files:
  - style: `app/assets/stylesheets/app_shell.scss`
  - view: `app/views/layouts/_topbar.html.erb`
  - view: `app/views/layouts/_footer.html.erb`
- implementation_notes: `.app-icon-btn`, 44×44 (`--tap-target`), `radius-md`, transparente em repouso. Compartilha o seletor de `:focus-visible` com `.app-avatar`, `.app-gadget` e os itens de navegação.
- last_verified: 2026-09-28

### [sidebar-navigation]
- status: implemented
- files:
  - view: `app/views/layouts/_sidebar.html.erb`
  - style: `app/assets/stylesheets/app_shell.scss`
  - javascript: `app/javascript/controllers/sidebar_controller.js`
  - helper: `app/helpers/navigation_helper.rb`
- implementation_notes: `offcanvas-lg offcanvas-start` — abaixo de 992px o Bootstrap fornece drawer, backdrop, Escape, trava de scroll e foco; a partir de 992px o próprio Bootstrap neutraliza o offcanvas e o `<aside>` vira coluna do grid. O Stimulus cobre somente o que o Bootstrap não dá: alternar/retrair no desktop (com `localStorage`), reexpandir ao abrir um submenu, e o fechar do drawer.
- last_verified: 2026-09-28

### [nav-item]
- status: implemented
- files:
  - view: `app/views/layouts/_nav_item.html.erb`
  - helper: `app/helpers/navigation_helper.rb`
  - style: `app/assets/stylesheets/app_shell.scss`
- implementation_notes: submenu com `<details>/<summary>` nativo em vez de JavaScript — o navegador já expõe o estado expandido/retraído a leitores de tela. Máximo de 2 níveis, ícone só no primeiro. Item sem rota é renderizado como `<span>` inerte com opacidade reduzida, nunca como link quebrado. A árvore de navegação é declarada em `NavigationHelper::NAVIGATION`.
- last_verified: 2026-09-28

### [footer]
- status: partial
- files:
  - view: `app/views/layouts/_footer.html.erb`
  - style: `app/assets/stylesheets/app_shell.scss`
- implementation_notes: a data corrente e o grupo de gadgets estão implementados, com `safe-area-inset-bottom` herdado do shell. Os dois gadgets (`data-gadget="calendar"` e `data-gadget="calculator"`) **não têm comportamento**: são apenas pontos de acionamento sem controller. Para não parecerem funcionais (§6), levam a classe `app-gadget--pending` (borda tracejada, sem hover) e o aviso "disponível em breve" no nome acessível — o rótulo visível continua limpo. Remover a classe ao implementar.
- last_verified: 2026-09-28

### [bottom-tab-bar]
- status: not_implemented
- files: []
- implementation_notes: especificação mantida no §6 como alternativa para telas sem sidebar. O shell atual navega por `[sidebar-navigation]` em modo drawer, então não há implementação.
- last_verified: 2026-09-28

### [page-header]
- status: implemented
- files:
  - view: `app/views/shared/_page_header.html.erb`
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - view: `app/views/categories/index.html.erb`
  - view: `app/views/categories/new.html.erb`
- implementation_notes: `.ds-page-header`. A ação contextual entra por bloco (`yield`), não por parâmetro — é markup de botão, e converter em string perderia o escape do ERB. No mobile os itens empilham por `flex-wrap`, sem barra inferior.
- last_verified: 2026-09-29

### [empty-state]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - view: `app/views/categories/index.html.erb`
- implementation_notes: `.ds-empty-state`. Usado na listagem de categorias sem registros, com CTA para criar a primeira. Nunca é tratado como erro — nenhum token de `danger` envolvido.
- last_verified: 2026-09-29

### [avatar]
- status: partial
- files:
  - helper: `app/helpers/user_helper.rb`
  - style: `app/assets/stylesheets/app_shell.scss`
- implementation_notes: `.app-avatar` é circular, 44×44, com gradiente em `--color-primary`/`--color-primary-hover` e texto em `--color-on-primary`. Só o fallback por iniciais está implementado: o model `User` não tem coluna de imagem e `User.from_omniauth` descarta `auth.info.image`, então a imagem do Google nunca é persistida. Falta a metade "imagem do usuário quando disponível" do §8.
- last_verified: 2026-09-28

---

# 6. Dados financeiros

### [expense-list]
- status: implemented
- files:
  - view: `app/views/shared/_expense_list.html.erb`
  - style: `app/assets/stylesheets/design_system/_components.scss`
- implementation_notes: Ordenacao (ver [expense-row]): o controller de arrasto fica no wrapper, nao na <ul>, porque a regiao viva precisa ser irma da lista e alvos do Stimulus tem de ser descendentes do controller. - implementation_notes: Tem id proprio porque e substituivel sozinha: criar uma despesa troca a lista e o resumo, e o resto da tela fica parado.
- last_verified: 2026-09-29

---

### [expense-row]
- status: implemented
- files:
  - view: `app/views/shared/_expense_row.html.erb`
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - javascript: `app/javascript/controllers/auto_submit_controller.js`
  - helper: `app/models/ledger_item.rb`
- implementation_notes: ORDENACAO implementada nesta tarefa: a ordem e do usuario, gravada em `position` (coluna nova, escopada por rubrica), com alca de arrasto (SortableJS) e setas ↑/↓ na alca focada, porque arrastar nao e alcancavel por teclado. Ver tambem [expense-list]. - implementation_notes: Duas faixas no celular, uma no desktop. Nome e categoria vem dos SNAPSHOTS do item, e a cor do chip vem de `LedgerItem#category_tone`, derivada do snapshot — renomear a categoria depois nao muda a rubrica antiga. O botao de remover reusa o [icon-button] ja implementado (`.app-icon-btn`). DESVIO REGISTRADO: o §7 pede que a remocao fique dentro da edicao no celular; aqui ela esta na linha, porque ainda nao existe edicao e a linha tem so essa acao — mover quando a edicao existir.
- last_verified: 2026-09-29

---

### [rubrica-picker]
- status: implemented
- files:
  - view: `app/views/shared/_rubrica_picker.html.erb`
  - view: `app/views/home/index.html.erb`
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - javascript: `app/javascript/controllers/picker_controller.js`
  - test: `test/controllers/home_picker_test.rb`
  - test: `test/controllers/ledgers_controller_test.rb`
- implementation_notes: UM markup para as duas apresentacoes, e UM controller. CELULAR (<= 991.98px): FOLHA SOBREPOSTA ancorada em `--app-topbar-h`, `max-block-size: min(70dvh, 28rem)`, cantos inferiores `--radius-lg`, `--elevation-2`, com backdrop de 40% — nao empurra mais o conteudo. O backdrop e o painel sao IRMAOS (dentro do painel o `overflow: hidden` da folha o recortaria), e o backdrop fica acima da topbar (z = `--app-z-topbar` + 1) e abaixo do drawer do Bootstrap (1045). Fecha por Esc, toque no backdrop e escolha de rubrica; o foco vai para a rubrica ativa ao abrir e volta ao botao ao fechar; `body.ds-sheet-open` trava a rolagem atras, e a classe e removida ao fechar E em `turbo:before-cache`/`disconnect`, senao o Turbo levaria o estado no cache e a tela seguinte nasceria travada. Cabecalho de 48px: busca de 40px ocupando a sobra a esquerda, acao `+` de 40x40 a direita. A busca aparece com QUALQUER quantidade de rubricas — nao ha mais corte em "mais de 6", e o titulo "Rubricas" que ocupava o lugar dela saiu do markup (o nome acessivel do painel continua vindo de `data-picker-label-value`). O campo e `type="search"` com `inputmode="search"`, `enterkeyhint="search"` e `autocomplete="off"` — e o que abre o teclado movel com a tecla certa. Filtra em tempo real (sem form, sem recarga), tolerante a maiusculas e acentos via `normalize("NFD")`, a MESMA regra do [combobox]. Com texto: resultados de TODAS as rubricas, sem recorte e sem "Ver todas"; sem resultado, a linha "Nenhuma rubrica encontrada" em `--color-text-muted`. O "×" aparece dentro do campo quando ha texto e devolve a lista recortada ao limpar; no celular o `::-webkit-search-cancel-button` nativo e escondido para nao haver dois controles iguais, e no desktop o nosso fica `display: none` (o nativo continua). Enter com EXATAMENTE um resultado seleciona e fecha. AO ABRIR o foco vai para a rubrica ativa, nunca para o campo: focar a busca levantaria o teclado sem ninguem ter pedido. Lista: `data-picker-limit-value` (no `.ds-home`) define quantas recentes aparecem — hoje 12, vindo do MARKUP e nao de constante no JS, para o numero ter uma fonte so, no lugar onde quem decide o produto olha. A ativa sempre entra; se estiver fora das recentes, substitui a ultima. Acima do limite, `Ver todas (N)` expande dentro da folha com rolagem propria. O cabecalho fica FORA do corpo rolavel, entao a busca nao rola junto com a lista. Linha de 48px com divisor de 1px, UM valor a direita (o que FALTA; o total existe no markup so para o desktop) ou um check discreto quando nao ha o que pagar; a ativa usa `--color-surface-muted` + check verde a esquerda do nome, sem pilula nem margem. Foco por `:focus-visible` (2px, `outline-offset: -2px`) em linhas e no "×", com `:focus` sem outline — sem isso a rubrica ativa, que recebe foco ao abrir, aparecia contornada de azul no toque. DESKTOP (>= 992px): inalterado — mesma coluna, busca e botao largo no rodape, `order` no cabecalho e o que faz o mesmo markup servir as duas telas; as regras de foco ficam DENTRO do bloco de celular justamente para nao mexer no desktop. Toda a apresentacao de celular vive num unico `@media (max-width: 991.98px)`; os blocos legados (`.ds-picker__current-*`, `.ds-picker__toggle`, `.ds-picker__actions`) foram REMOVIDOS.
- last_verified: 2026-09-30

---

### [ledger-summary]
- status: implemented
- files:
  - view: `app/views/shared/_ledger_summary.html.erb`
  - style: `app/assets/stylesheets/design_system/_components.scss`
- implementation_notes: Total/pago/falta + barra. Faixa de apoio, sem superficie propria — nao e [balance-card]. `Falta` recebe peso relativo. Tem id proprio para o turbo_stream substituir so ele ao marcar pago.
- last_verified: 2026-09-29

---

### [progress-bar]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_components.scss`
- implementation_notes: Sem limiares de alerta: pagar tudo e o objetivo, e passar de 100% nao e erro. O progresso e exposto tambem em texto pelos tres numeros do resumo.
- last_verified: 2026-09-29


---

### [category-badge]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - style: `app/assets/stylesheets/design_system/_theme_app.scss`
  - style: `app/assets/stylesheets/_palette.scss`
  - helper: `app/models/category.rb`
  - view: `app/views/categories/index.html.erb`
- implementation_notes: `.ds-category-badge` + `--<tom>` para os 10 tons da subpaleta, gerados em `@each`. A tinta e a cor de texto de cada tom são tokens de contexto (`--color-cat-<tom>-bg` / `-text`); vermelho e âmbar ficaram fora porque o §3 os reserva para erro e atenção. O tom vem de `Category#color_tone`, derivado do nome por MD5 — `String#hash` do Ruby é semeado por processo e mudaria a cor a cada reinício do servidor.
- last_verified: 2026-09-29

### [balance-card]
- status: not_implemented
- files: []
- implementation_notes: especificação existe no §7; nenhuma implementação.
- last_verified: 2026-09-28

### [summary-card]
- status: not_implemented
- files: []
- implementation_notes: especificação existe no §7; nenhuma implementação.
- last_verified: 2026-09-28

### [financial-summary-grid]
- status: not_implemented
- files: []
- implementation_notes: especificação existe no §7; nenhuma implementação.
- last_verified: 2026-09-28

### [budget-progress-bar]
- status: not_implemented
- files: []
- implementation_notes: especificação existe no §7; nenhuma implementação.
- last_verified: 2026-09-28

---

# 7. Feedback

### [modal]
- status: implemented
- files:
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - javascript: `app/javascript/controllers/modal_controller.js`
  - javascript: `app/javascript/controllers/modal_close_controller.js`
  - view: `app/views/home/index.html.erb`
- implementation_notes: Usa o <dialog> nativo: foco preso, Escape e backdrop vem do navegador. O CSS decide so a forma — folha na base abaixo de 1200px, dialogo centralizado acima. Descarte protegido: com campo preenchido, tocar no fundo nao fecha. `modal_close_controller` fecha apos criacao bem-sucedida.
- last_verified: 2026-09-29

---

### [snackbar]
- status: implemented
- files:
  - view: `app/views/shared/_snackbar.html.erb`
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - javascript: `app/javascript/controllers/snackbar_controller.js`
  - view: `app/views/ledger_items/destroy.turbo_stream.erb`
  - view: `app/views/ledger_items/restore.turbo_stream.erb`
- implementation_notes: Variante `undo` em uso: remover uma despesa da rubrica age e oferece desfazer, em vez de pedir confirmacao. O desfazer NAO usa coluna de exclusao logica — os snapshots viajam em campos ocultos no corpo do proprio snackbar e voltam pelo endpoint de restore, que escopa ledger e expense por current_user. Some sozinho em 8s, pausando com o ponteiro ou o foco em cima.
- last_verified: 2026-09-29

---

### [modal-confirm]
- status: implemented
- files:
  - view: `app/views/shared/_modal_confirm.html.erb`
  - style: `app/assets/stylesheets/design_system/_components.scss`
  - view: `app/views/ledgers/_delete_modal.html.erb`
  - test: `test/controllers/ledgers_controller_test.rb`
- implementation_notes: Usado para excluir rubrica, que leva as despesas junto. `column-reverse` deixa Cancelar na zona do polegar e o botao destrutivo fora dela, como o §8 pede. DESVIO REGISTRADO: o §8 preve tambem Desfazer depois do dialogo para rubricas com despesas; aqui so ha a confirmacao previa — restaurar uma rubrica com N itens exigiria carregar todos eles no corpo do snackbar, e a confirmacao ja e a salvaguarda.
- last_verified: 2026-09-29

---

# 8. Telas

### [lock-screen]
- status: implemented
- files:
  - view: `app/views/lock/show.html.erb`
  - controller: `app/controllers/lock_controller.rb`
  - route: `config/routes.rb` (`get "sem-permissao"`, nome `lock`)
  - locale: `config/locales/auth.pt-BR.yml` (`auth.screens.lock_show`)
- implementation_notes: tela de quem está logado mas não tem perfil. NÃO tem componente próprio: reusa `[auth-screen-pattern]` (`layout "devise"` — tema dark, `auth-card` centralizado, sem shell) e `[button]` na variante `primary` + `block`. O título e a mensagem vêm do `AuthHelper` pela chave `auth.screens.lock_show.*`, do mesmo jeito que as telas do Devise, então a view só traz o botão "Sair" (`button_to` com `method: :delete`, porque `config.sign_out_via = :delete` e sem JS é justamente quando o usuário mais precisa sair). O gate que leva para cá fica no `ApplicationController` (`require_profile`, com `unless: :devise_controller?`) e manda por REDIRECT 303, não por 403 renderizado — num `turbo_stream` o Turbo não tem `responseHTML` e não desenharia nada.
- last_verified: 2026-09-30

### [auth-screen-pattern]
- status: implemented
- files:
  - view: `app/views/layouts/devise.html.erb`
  - style: `app/assets/stylesheets/devise_auth.scss`
  - helper: `app/helpers/auth_helper.rb`
- implementation_notes: o card é aplicado pelo layout, não por parcial: os controllers em `app/controllers/users/` declaram `layout "devise"` e qualquer view renderizada por eles ganha shell, cabeçalho e flash automaticamente. O título vem de `auth_helper`. O bundle `devise_auth.css` é carregado só nessas telas via `layouts/_head` (`extra_stylesheet`).
- last_verified: 2026-09-28

### [auth-card]
- status: implemented
- files:
  - view: `app/views/layouts/devise.html.erb`
  - style: `app/assets/stylesheets/devise_auth.scss`
  - style: `app/assets/stylesheets/design_system/_theme_auth.scss`
- implementation_notes: `.auth-card` usa `--color-surface-glass` com `backdrop-filter: blur(20px)`, `radius-lg` e `--elevation-2`. No mobile encosta na base (`margin-top: auto`, cantos superiores arredondados); a partir de 640px vira card flutuante centralizado com `max-width: 400px`. Tema **dark**, fornecido por `_theme_auth.scss` — não pelo tema da área autenticada.
- last_verified: 2026-09-28

### [login-screen]
- status: implemented
- files:
  - view: `app/views/devise/sessions/new.html.erb`
- implementation_notes: usa `[auth-screen-pattern]`. O login por Google vem de `app/views/devise/shared/_links.html.erb` via `button_to` (o callback é POST, protegido por `omniauth-rails_csrf_protection`), compartilhado com as demais telas de Devise. Há estilo `.auth-btn--passkey` pronto para WebAuthn, que ainda não existe no projeto — está documentado em comentário na própria view e em `devise_auth.scss`.
- last_verified: 2026-09-28

### [registration-screen]
- status: implemented
- files:
  - view: `app/views/devise/registrations/new.html.erb`
  - view: `app/views/devise/registrations/edit.html.erb`
- implementation_notes: cadastro e edição de conta usam `[auth-screen-pattern]`. A edição inclui bloco de cancelamento de conta (`.auth-section`).
- last_verified: 2026-09-28

### [password-recovery-screen]
- status: implemented
- files:
  - view: `app/views/devise/passwords/new.html.erb`
  - view: `app/views/devise/passwords/edit.html.erb`
- implementation_notes: solicitação e redefinição de senha usam `[auth-screen-pattern]`.
- last_verified: 2026-09-28

---

### [category-form-screen]
- status: implemented
- files:
  - view: `app/views/categories/new.html.erb`
  - view: `app/views/categories/edit.html.erb`
  - view: `app/views/categories/_form.html.erb`
  - controller: `app/controllers/categories_controller.rb`
  - test: `test/controllers/categories_controller_test.rb`
- implementation_notes: tela criada no §10 nesta mesma tarefa, espelhando a forma de `[transaction-form-screen]`: `[page-header]`, form, um `[input-text]`, `[error-message]`, CTA `primary` e cancelar `secondary`. A edição não oferece exclusão — excluir é ação da lista, onde a consequência fica visível ao lado do item.
- last_verified: 2026-09-29

### [reports-screen]
- status: not_implemented
- files: []
- implementation_notes: rota e view inexistentes. A navegação já aponta para "Relatórios" como item pendente (sem rota).
- last_verified: 2026-09-28

---

# 9. Lacunas conhecidas

Itens que a spec cobre (ou deveria cobrir) e que ainda não estão resolvidos:

1. `[typography-tokens]` — o §4 não define valores (categorias sem tamanho, peso
   ou line-height). Enquanto isso, tamanhos de fonte são literais por componente.
2. Breakpoints — a Rule 9 cita `breakpoints` entre os foundations, mas o §4 não
   os define. Hoje o projeto usa 992px (lg do Bootstrap) e um 640px avulso no
   card de autenticação.
3. `[footer]` — os dois gadgets não têm comportamento. Foram marcados como
   pendentes na interface (classe `app-gadget--pending`, borda tracejada, aviso
   no nome acessível), mas continuam sendo botões sem ação.
4. `[avatar]` — falta persistir e renderizar a imagem do usuário (ver §5).
5. Componentes do §7 ainda não implementados — `[balance-card]`,
   `[summary-card]`, `[transaction-list]` e `[transaction-list-item]`. Os
   tokens de que precisam já existem, e `[category-badge]` já serve de exemplo
   de componente de dados resolvido.
6. Telas pendentes do §10: `[dashboard-screen]` (a raiz ainda é o scaffold do
   Rails), `[transactions-index-screen]`, `[transaction-form-screen]` e
   `[reports-screen]`. O domínio por trás delas já existe e está testado, mas
   as telas não foram especificadas com o detalhe que o §10 exige — mesmo
   caminho percorrido em `[categories-index-screen]`.

7. `[lock-screen]` — **a tela não existe no `DESIGN-SYSTEM.md`**. O §10 lista as
   telas do produto e não há nenhuma de "sem permissão"; a tela foi montada
   reusando `[auth-screen-pattern]` e `[button]`, por decisão de produto (o
   usuário está fora do app, e o visual de fora é o que corresponde). Ou o §10
   ganha a especificação, ou a tela segue existindo fora do Design System —
   hoje ela é a única tela do app nessa situação.

8. `[rubrica-picker]` — o §7 descreve, para o celular, uma **folha sobreposta**
   fechada por backdrop/Esc, um estado recolhido com ação "Ver todas" e uma
   busca no cabeçalho. Isso está implementado. O que ficou divergente da spec é
   o **número de rubricas recentes**: o §7 diz "últimas 6" e o produto definiu
   **12**, com o valor vindo de `data-picker-limit-value`. Além disso o §7
   condiciona a busca a "mais de 6 rubricas" e o produto decidiu que ela aparece
   **sempre**. Ou o §7 passa a dizer 12 e "sempre", ou o código volta ao que
   está escrito — hoje os dois não batem.

> Nenhuma pendência de tema: a separação autenticação **dark** / área autenticada
> **light** está implementada e é decidida por contexto, sem alternância.

---

# 10. Processo de atualização

Ao implementar ou alterar UI:

1. consulte a especificação correspondente no `DESIGN-SYSTEM.md`;
2. procure neste registro uma implementação existente;
3. confirme no filesystem/repositório se os arquivos declarados realmente existem;
4. se encontrar implementação equivalente fora do registro, **registre-a antes de criar outra**;
5. se reutilizar um componente sem alterá-lo, não é necessário editar seu registro apenas para listar uma nova view consumidora;
6. se criar ou alterar arquivos estruturais do componente, atualize `files`, `status`, `implementation_notes` e `last_verified`;
7. nunca coloque decisões de estética novas neste arquivo — elas pertencem ao `DESIGN-SYSTEM.md`.
