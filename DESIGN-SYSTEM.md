# DESIGN-SYSTEM.md

> **Fonte normativa e única de UI/UX do projeto.**
>
> Este arquivo descreve **como a interface deve ser**: fundamentos visuais, componentes, padrões de composição e especificações de telas. Ele **não controla se algo já foi implementado, onde o código está ou quais views já usam um componente**. Esse controle pertence exclusivamente ao `COMPONENT-REGISTRY.md`.

---

## 1. Papel deste documento

Toda implementação de interface deve nascer deste arquivo.

Antes de construir ou alterar uma tela, o Claude Code deve localizar aqui:

1. a especificação da **tela**;
2. a composição obrigatória dessa tela;
3. os **componentes** usados pela tela;
4. a especificação individual de cada componente;
5. os tokens, variantes, estados, comportamento responsivo e regras de acessibilidade aplicáveis.

O Claude Code não deve inventar silenciosamente estética, layout, componente, variante ou padrão que não esteja descrito aqui.

Se uma tela ou componente necessário não possuir especificação suficiente neste documento, a implementação visual deve ser interrompida naquele ponto e a lacuna deve ser sinalizada. Primeiro define-se o padrão neste arquivo; depois o código é implementado.

---

## 2. Separação de responsabilidades

### `DESIGN-SYSTEM.md`
Responde:

> **Como a interface deve ser?**

Contém:
- design tokens;
- princípios visuais;
- componentes e suas APIs visuais;
- variantes e estados;
- padrões de interação;
- composição das telas;
- comportamento mobile/desktop;
- regras de acessibilidade.

### `COMPONENT-REGISTRY.md`
Responde:

> **O que já existe no código e onde está?**

Contém:
- status de implementação;
- arquivos reais;
- dependências técnicas;
- observações de implementação.

### `CLAUDE.md`
Responde:

> **Qual processo o Claude Code deve seguir?**

Ele obriga a consulta aos dois documentos e define o fluxo de execução.

---

# 3. Stack e princípios gerais

- Rails 8.
- Views em ERB.
- Autenticação via Devise.
- Bootstrap como base de frontend.
- Componentes customizados devem **estender ou especializar** o Bootstrap; não recriar funcionalidade que o Bootstrap já resolva adequadamente.
- O produto tem **dois contextos visuais distintos e intencionais**:

  ```text
  Autenticação:
  theme = dark

  Área autenticada:
  theme = light
  ```

- O tema pertence ao **contexto**, não a uma preferência do usuário nem ao
  sistema operacional. Não existe troca de tema em tempo de execução.
- Mobile-first: referência inicial de 375px.
- Desktop de referência: 1280px.
- Área tocável mínima: 44px.
- Ações primárias em mobile devem, quando compatível com a tela, permanecer em região confortável para uso com o polegar.
- Vermelho é reservado a erro, perigo e estouro real de orçamento. Saída/gasto normal não deve ser vermelha apenas por ser gasto.

---

# 4. Foundations / Design tokens

## [color-tokens]

### Objetivo
Paleta semântica oficial do produto. Componentes devem consumir tokens; não devem introduzir cores arbitrárias.

### Regra de contexto

```text
Autenticação:
theme = dark

Área autenticada:
theme = light
```

- **Autenticação** — login, cadastro, recuperação de senha, confirmação, unlock
  e demais telas do layout de autenticação — é **dark**. Essa identidade **não é
  inconsistência nem dívida técnica**, e não deve ser convertida para light.
- **Área autenticada** — tudo depois do login — é **light**, e o light é o seu
  **padrão**: não depende de `data-theme`, de classe no `<html>` nem de
  `prefers-color-scheme`.
- Os dois contextos **nunca coexistem** na mesma tela.

### Tokens compartilhados
Valem nos dois contextos. Um contexto não deve sobrescrevê-los.

- `primary`: `#0FA968` — marca, CTA, foco, valores positivos e destaques.
- `primary-hover`: `#10B981`.
- `on-primary`: `#06251A` — texto sobre preenchimento `primary`.
- `success`: `#22C55E`.
- `warning`: `#F59E0B`.
- `danger`: `#EF4444`.
- `info`: `#5B8DEF` — links, foco e informação secundária.
- Variantes suaves `*-bg` e `*-border` de `success`, `warning`, `danger` e
  `info`, para faixas e mensagens de baixa intensidade.

### Tokens de contexto
Cada contexto define **o mesmo conjunto de nomes** com valores próprios. Um
componente consome o nome e nunca decide qual tema está ativo.

- `bg` — fundo da página;
- `surface` — superfície principal (cards, barras de navegação);
- `surface-muted` — superfície secundária;
- `surface-hover`, `surface-input`;
- `text`, `text-muted`, `text-disabled`;
- `border`, `border-strong`;
- `primary-bg` — tinta de seleção/ativo;
- `primary-text`, `success-text`, `warning-text`, `danger-text`, `info-text`;
- `focus-ring`, `focus-ring-info`;
- `elevation-1`, `elevation-2`;
- `shadow-primary`.

#### Área autenticada — light (padrão)

| Token | Valor |
|---|---|
| `bg` | `#F7F8FA` |
| `surface` | `#FFFFFF` |
| `surface-muted` | `#EFF2F5` |
| `surface-hover` | `rgba(17,20,24,0.04)` |
| `surface-input` | `#FFFFFF` |
| `text` | `#111418` |
| `text-muted` | `#5C6470` |
| `text-disabled` | `#98A0AB` |
| `border` | `rgba(0,0,0,0.08)` |
| `border-strong` | `rgba(0,0,0,0.16)` |
| `primary-bg` | `#E7F6EF` |
| `primary-text` | `#0B7A4A` |
| `success-text` | `#17703A` |
| `warning-text` | `#A34A08` |
| `danger-text` | `#B91C1C` |
| `info-text` | `#2563EB` |
| `focus-ring` | `rgba(15,169,104,0.25)` |
| `focus-ring-info` | `rgba(37,99,235,0.28)` |
| `elevation-1` | `0 1px 2px rgba(17,20,24,0.06)` |
| `elevation-2` | `0 10px 30px -12px rgba(17,20,24,0.18)` |
| `shadow-primary` | `0 8px 20px -10px rgba(15,169,104,0.45)` |

Direção visual desta área: clara, limpa, com respiro. Três níveis de superfície
— fundo off-white, superfície branca e superfície secundária em cinza muito
claro — separados por **borda discreta**, não por sombra. Nada de glassmorphism
escuro nem de peso visual de dashboard corporativo.

#### Autenticação — dark

| Token | Valor |
|---|---|
| `bg` | `#0B0F14` |
| `surface` | `#12181F` |
| `surface-muted` | `#1A222B` |
| `surface-hover` | `rgba(255,255,255,0.05)` |
| `surface-input` | `rgba(255,255,255,0.03)` |
| `surface-glass` | `rgba(18,24,31,0.6)` |
| `text` | `#E8EAED` |
| `text-muted` | `#8A929E` |
| `text-disabled` | `#5A626D` |
| `border` | `rgba(255,255,255,0.08)` |
| `border-strong` | `rgba(255,255,255,0.16)` |
| `primary-bg` | `rgba(15,169,104,0.16)` |
| `primary-text` / `success-text` / `warning-text` / `danger-text` / `info-text` | mesma cor do preenchimento correspondente |
| `focus-ring` | `rgba(15,169,104,0.22)` |
| `focus-ring-info` | `rgba(91,141,239,0.28)` |
| `elevation-1` | `0 1px 2px rgba(0,0,0,0.32)` |
| `elevation-2` | `0 16px 40px -20px rgba(0,0,0,0.85)` |
| `shadow-primary` | `0 8px 20px -8px rgba(15,169,104,0.55)` |

Tokens **exclusivos** deste contexto, por não existirem na área autenticada:
`surface-glass`, e os brilhos `glow-primary` / `glow-info` do fundo.

### Regras de contraste

- As cores de **preenchimento** (`primary`, `success`, `warning`, `danger`,
  `info`) **não devem ser usadas como texto** sobre superfície clara: nenhuma
  delas atinge 4,5:1 sobre branco. Para uso textual existem as variantes
  `*-text`, dimensionadas pelo pior caso das superfícies do contexto.
- No contexto dark as variantes `*-text` repetem a cor de preenchimento, porque
  sobre fundo quase preto elas já passam em AA.
- Texto desabilitado é isento de AA (WCAG 1.4.3 exclui componentes inativos),
  mas deve continuar legível como estado atenuado.

### Regra
No código de componentes, preferir CSS custom properties correspondentes aos tokens, e não valores hexadecimais soltos.

---

## [typography-tokens]

### Objetivo
Escala tipográfica consistente para leitura de interface e dados financeiros.

### Famílias
- Interface: sans-serif do sistema / stack compatível com Bootstrap.
- Valores financeiros: fonte com `font-variant-numeric: tabular-nums`; fonte monoespaçada somente quando fizer sentido visual.

### Hierarquia
- `display`: destaque financeiro excepcional.
- `h1`: título principal da tela.
- `h2`: título de seção.
- `h3`: título de card/bloco.
- `body`: conteúdo principal.
- `body-secondary`: conteúdo auxiliar.
- `caption`: datas, metadados e rótulos compactos.
- `money`: valores financeiros com números tabulares.

### Regra
Hierarquia deve ser produzida por tokens/tipos semânticos; não por tamanhos arbitrários em cada view.

---

## [spacing-tokens]

Escala oficial em múltiplos de 4px:

- `space-1`: 4px
- `space-2`: 8px
- `space-3`: 12px
- `space-4`: 16px
- `space-6`: 24px
- `space-8`: 32px
- `space-12`: 48px
- `space-16`: 64px

Padding, margin e gap devem usar esta escala sempre que possível.

---

## [radius-tokens]

- `radius-sm`: 8px
- `radius-md`: 12px
- `radius-lg`: 16px
- `radius-pill`: 999px

Cards principais usam `radius-lg`; inputs e botões, `radius-md`; badges/chips, `radius-pill`.

---

## [elevation-tokens]

Escala de profundidade, com os mesmos nomes nos dois contextos:

- `elevation-0`: sem sombra.
- `elevation-1`: separação sutil de superfície.
- `elevation-2`: menus, dropdowns, modais e elementos flutuantes.

Os valores são **de contexto** (ver `[color-tokens]`), porque sombra é
exatamente o que muda entre os temas:

- no contexto **dark** (autenticação), a diferenciação de superfície deve
  depender mais de contraste de camada e borda do que de sombras pesadas;
- no contexto **light** (área autenticada), a sombra é contida: o mecanismo
  principal de separação continua sendo a borda de 1px, e a sombra aparece
  sobretudo no que flutua (dropdown).
- `elevation-0` não é declarado como token — a ausência de sombra é a ausência
  da propriedade.

---

# 5. Componentes de formulário

## [button]

### Uso
Ações do usuário.

### Variantes

#### `primary`
- ação principal da tela ou bloco;
- fundo `primary`;
- texto em `on-primary` (**não** branco: branco sobre `#0FA968` dá 3,05:1 e
  reprovaria em WCAG AA; `on-primary` dá 5,36:1);
- altura mínima 44px;
- largura total em mobile quando for CTA principal de formulário;
- hover com alteração discreta de luminosidade/elevação;
- foco visível;
- loading com spinner sem alterar drasticamente a largura;
- disabled com redução de ênfase e bloqueio de interação.

#### `secondary`
- cancelar, voltar ou ação de menor prioridade;
- fundo transparente ou superfície discreta;
- borda sutil;
- texto primário.

#### `danger`
- somente ações destrutivas reais;
- utilizar token `danger`;
- não usar para gasto/saída normal.

#### `oauth`
- autenticação por provedor externo (Google);
- fundo transparente e borda sutil, para não competir com o `primary` de entrar;
- **exclusiva do contexto de autenticação**.

#### `passkey`
- login sem senha (WebAuthn);
- quando existir, é a ação primária do login e fica acima do formulário;
- **exclusiva do contexto de autenticação.**

### Tamanhos e largura
- `default`: 48px de altura. Acima do mínimo de 44px, e é a altura dos CTAs;
- `compact`: 44px, para ações em linha (linha de lista, barra de ações). Nunca
  abaixo de 44px;
- `block`: ocupa a largura total. É o padrão para o CTA principal de um
  formulário; ações em linha **não** usam este modificador.

### Regra de composição
Uma tela não deve competir com múltiplos CTAs primários de mesma hierarquia no mesmo contexto.

`[button]` é **um** componente usado nos dois contextos visuais. O tema vem dos
tokens de contexto, nunca de uma segunda classe de botão — não deve existir um
botão "de autenticação" paralelo ao botão da área autenticada.

---

## [input-text]

- label acima do campo;
- altura mínima 44px;
- borda sutil;
- background compatível com o tema;
- placeholder em `text-muted`;
- foco com destaque discreto usando `info` ou `primary`;
- erro deve combinar mensagem textual + sinal visual; nunca depender apenas de cor.

Estados:
- default;
- focus;
- filled;
- disabled;
- error.

---

## [input-currency]

Variação semântica de `[input-text]` para valores monetários.

- prefixo `R$` visualmente estável, fora da área de digitação;
- valor alinhado à direita quando favorecer leitura;
- números tabulares;
- formatação brasileira (`.` de milhar, `,` decimal, sempre duas casas);
- herda **todos** os estados de `[input-text]`.

### Digitação
- o campo abre **teclado numérico** no celular (`inputmode="decimal"`). Para um
  app financeiro, errar isso é o defeito de usabilidade mais comum que existe;
- o dígito entra pela **direita**: digitar `11990` produz `R$ 119,90`. Não há
  digitação de separador — vírgula e ponto são consequência, não entrada;
- **zero é um valor válido** e não é erro. Cadastrar uma despesa antes de saber
  o valor é um caso legítimo.

### Acessibilidade
- o valor é anunciado como **moeda**, não como número cru lido dígito a dígito;
- o prefixo `R$` não é lido como parte do valor.

---

## [combobox]

### Uso
Escolha de um item entre muitos, com busca. Usado no seletor de categoria, onde
o usuário pode ter dezenas de categorias.

### Composição
1. campo de texto que abre a lista ao receber foco;
2. lista de opções, filtrável pela digitação;
3. quando não há correspondência exata, uma última opção **criar**.

### Aparência
- o campo se parece com `[input-text]`;
- a lista é uma superfície elevada (`surface`, `elevation-2`), com a mesma
  `border` discreta do resto;
- cada opção carrega seu `[category-badge]` — cor **e** nome, nunca só a cor.

### Ordem das opções
1. **Recentes** — as últimas usadas pelo usuário;
2. **Todas**, em ordem alfabética.

### Criar na hora
Quando o texto digitado não corresponde exatamente a nenhuma opção, a última
linha é `Criar "<texto>"`. Um toque cria e já seleciona.

- a categoria criada recebe automaticamente um tom da subpaleta — a cor e o
  nome continuam editáveis depois na tela de Categorias;
- se já existir categoria equivalente (ignorando maiúsculas e acentos), a opção
  de criar **não aparece**.

### Busca
Tolerante a acentos: `comunicacao` encontra `Comunicação`.

### Mobile
O seletor **substitui o conteúdo do modal**, com uma seta de voltar no topo e o
teclado já aberto — nunca um modal sobre outro modal.

### Desktop
A lista abre sobre o diálogo, ancorada ao campo.

### Acessibilidade
- navegação por setas, `Enter` seleciona, `Escape` fecha;
- o campo anuncia que é uma lista de sugestões (`role="combobox"`);
- a contagem de resultados é anunciada quando o filtro muda.

---

## [checkbox-toggle]

- checkbox para seleção/aceite;
- toggle para preferências binárias persistentes;
- label clicável;
- área interativa mínima de 44px;
- estado de foco visível.

---

## [error-message]

- bloco compacto;
- ícone opcional + texto explícito;
- token `danger` com fundo de baixa intensidade;
- cantos `radius-md`;
- deve indicar claramente o que o usuário precisa corrigir;
- para formulários Devise, substitui visualmente a lista de erros padrão quando aplicável.

---

# 6. Navegação e estrutura

## [brand-mark]

### Uso
Identidade visual do produto. É o único elemento autorizado a representar a
marca, e existe em três materializações — o selo da `[top-navbar]`, o marco do
`[auth-card]` e o ícone do produto (favicon / app icon). Todas são o **mesmo**
componente; mudar o desenho da marca significa mudar as três.

### Composição
- container preenchido com o gradiente da marca;
- a marca em si (`on-primary`), centrada;
- nada mais. Sem texto, sem borda, sem ornamento.

### Aparência
- preenchimento `linear-gradient(135deg, primary, primary-hover)`;
- marca sempre em `on-primary`, **nunca em branco**: branco sobre `primary` dá
  3,05:1 e reprovaria em WCAG AA, enquanto `on-primary` dá 5,35:1;
- sem `border`, sem contorno de separação.

### Variantes

#### `seal`
Selo com glifo, ao lado do nome do produto na `[top-navbar]`.
- container quadrado com `radius-md`;
- glifo de linha, na cor da marca.

#### `monogram`
Marco com a inicial do nome do produto, no cabeçalho do `[auth-card]`.
- container `radius-pill`;
- inicial em peso alto e `letter-spacing` negativo;
- admite `shadow-primary`, por estar sobre superfície escura.

#### `icon`
A marca sozinha, sem texto ao lado: aba do navegador, atalho, ícone instalado.
- container sangrado (a marca ocupa todo o quadro), com raio proporcional
  (~22%, o mesmo raio de squircle do iOS) — e **não** `radius-md`, que é um
  token amarrado ao tamanho do selo de 34px e, escalado, transformaria o
  quadrado num blob;
- glifo maior que no `seal`, porque não há texto para carregar a leitura;
- versões sangradas e **opacas** para quando o sistema aplica a própria máscara
  (iOS). Transparência nas quinas ali vira preenchimento preto.

### Tamanho mínimo
O `icon` só é legível a partir de **32px**. Abaixo disso o glifo de linha perde
o desenho interno e vira um borrão: a marca continua reconhecível pela cor e
pela silhueta, mas deixa de comunicar "dinheiro". Não trocar o glifo do `icon`
por um simplificado sem antes especificar essa variante aqui.

### Mobile
O `seal` pode ceder lugar ao nome do produto quando faltar largura, como
descrito em `[top-navbar]`. O `monogram` não muda.

### Desktop
Tamanhos estáveis, sem variação por breakpoint.

### Acessibilidade
- a marca **nunca** carrega significado sozinha: quando há nome do produto em
  texto ao lado, o container é decorativo (`aria-hidden`); quando não há, ela
  precisa de nome acessível;
- o selo da topbar é envolvido por link para a raiz, e herda o `:focus-visible`
  compartilhado dos controles de navegação.

---

## [app-shell]

### Uso
Estrutura raiz das telas autenticadas.

### Composição
1. `[top-navbar]` fixa no topo, atravessando a largura total;
2. `[sidebar-navigation]` como navegação principal, em coluna própria à esquerda no desktop;
3. container principal de conteúdo, que recebe a view corrente;
4. `[footer]` fixo na base, atravessando a largura total.

### Tema
`theme = light`. Esta é a área autenticada, e o light é o seu padrão.

- superfície da página em `bg` (off-white);
- topbar, sidebar e rodapé em `surface` (branco);
- o conteúdo vive sobre `bg`, então as superfícies brancas se destacam sem
  precisar de sombra;
- separação entre áreas por `border` de 1px — a sombra não é o mecanismo
  principal de hierarquia aqui;
- **não** usar glassmorphism, brilhos de fundo nem sombras pesadas: isso é
  linguagem visual do contexto de autenticação.

### Hierarquia
- topbar e rodapé são fixos e pertencem ao shell, não à view;
- a sidebar navega; o conteúdo é o único elemento que muda entre telas;
- a view nunca deve renderizar sua própria navegação principal.

### Mobile
- conteúdo em coluna única;
- a sidebar **não** ocupa coluna: vira drawer sobreposto, acionado pela `[top-navbar]`;
- padding lateral `space-4`;
- reservar espaço inferior para o rodapé fixo e para `safe-area-inset-bottom`.

### Desktop
- a sidebar ocupa coluna de largura estável e pode ser retraída;
- conteúdo centralizado na área restante;
- largura máxima aproximada de 1280px;
- padding horizontal ampliado conforme viewport (`space-6` como referência).

### Acessibilidade
- o conteúdo principal é o `<main>` da página;
- no mobile, o drawer deve prender o foco, fechar com Escape e expor rótulo acessível;
- o controle que abre a navegação mobile indica seu estado (`aria-expanded`) e referencia o elemento que controla.

---

## [auth-card]

### Uso
Container padrão das telas de autenticação Devise.

### Tema
`theme = dark`. Este componente pertence ao contexto de **autenticação**, que é
escuro por decisão de design. **Não** deve ser convertido para light nem
"alinhado" ao tema da área autenticada: são contextos visuais distintos e
intencionalmente diferentes.

### Aparência
- fundo de página com gradiente discreto;
- card elevado;
- efeito de glassmorphism sutil quando suportado;
- `backdrop-filter: blur(20px)` apenas como aprimoramento visual, sem comprometer legibilidade;
- alto contraste de texto;
- estrutura vertical simples.

### Conteúdo típico
1. identidade/nome do app;
2. título da ação;
3. texto auxiliar opcional;
4. formulário;
5. CTA primário;
6. links secundários.

### Responsividade
- mobile: card ocupa a maior parte da largura útil com margem lateral consistente;
- desktop: largura controlada e centralizada.

### Referência adicional
Quando existente no projeto, `PROMPT-DEVISE-AUTH` pode detalhar o conteúdo das telas, mas não substitui as regras visuais deste documento.

---

## [top-navbar]

### Uso
Navegação superior das áreas autenticadas.

### Composição
- identidade/logo do app à esquerda;
- controles de navegação junto à identidade, à esquerda;
- espaço central livre ou contextual;
- perfil do usuário à direita;
- `[avatar]` no controle de perfil;
- dropdown com ações de conta quando necessário.

### Controles de navegação
A topbar hospeda o acesso à navegação principal, com dois `[icon-button]` que
nunca coexistem (um é mobile, o outro desktop):

- **drawer (mobile)**: abre a `[sidebar-navigation]` sobreposta;
- **retração (desktop)**: expande ou retrai a coluna da `[sidebar-navigation]`,
  refletindo o estado em `aria-expanded`.

### Aparência
- superfície `surface` (branca no contexto light);
- separação inferior com `border` de 1px, não com sombra;
- marca legível em `text` sobre a superfície, com o selo da marca em `primary`;
- avatar e controles com contraste adequado sobre a superfície clara;
- altura estável entre telas.

### Mobile
- manter apenas informações essenciais;
- ocultar texto redundante do usuário quando necessário;
- preservar avatar e ações principais;
- a identidade textual do app pode ceder lugar aos controles quando faltar largura.

### Desktop
- pode exibir nome do usuário ao lado do avatar.

---

## [icon-button]

### Uso
Ação compacta representada por um ícone, sem rótulo visível. Usado nos controles
de navegação da `[top-navbar]` e em acionadores compactos do `[footer]`.

### Composição
- apenas ícone, sem texto visível;
- nome acessível obrigatório (`aria-label` ou equivalente).

### Aparência
- formato quadrado com `radius-md`;
- fundo transparente em repouso;
- ícone em `text-muted`.

### Estados
- **hover**: superfície discreta e ícone em `text`;
- **focus**: anel de foco visível em `info`;
- **disabled**: redução de ênfase e bloqueio de interação.

### Regra
Não é uma variante de `[button]`: não carrega texto, não tem variantes
semânticas (`primary`/`danger`) e existe apenas em contexto de chrome da
aplicação. Ações com consequência devem usar `[button]`.

### Acessibilidade
- área tocável mínima de 44px, mesmo que o ícone seja menor;
- nunca depender do ícone sozinho para comunicar estado ou risco.

---

## [sidebar-navigation]

### Uso
Navegação principal das áreas autenticadas. É o destino de navegação do
`[app-shell]`.

### Composição
- agrupamento de `[nav-item]`;
- `[icon-button]` de fechamento no cabeçalho do drawer (mobile).

### Aparência
- superfície principal (`surface`) — no contexto light, branca sobre um conteúdo
  off-white, o que já a diferencia sem precisar de sombra;
- separação por borda sutil (`border`) na lateral que encosta no conteúdo;
- itens inativos em `text-muted`;
- **item ativo** em `primary-text` sobre `primary-bg`. Verde é a identidade da
  marca e o item ativo é um dos poucos lugares onde ele aparece;
- sem sombra pesada.

### Variantes
- **expandida**: ícone + rótulo; comportamento padrão no desktop;
- **retraída**: somente ícones, com o mesmo alvo de toque; disponível apenas no
  desktop.

### Estados
- expandida;
- retraída (desktop, com a preferência preservada entre visitas);
- drawer aberto (mobile);
- drawer fechado (mobile).

### Mobile
- não ocupa coluna: apresenta-se como drawer sobreposto, aberto pela `[top-navbar]`;
- fecha por Escape, por toque fora e pelo controle de fechamento do cabeçalho;
- prende o foco enquanto aberta;
- a regra de "somente ícones" **não** se aplica: no drawer sempre há rótulo.

### Desktop
- coluna de largura estável, independente do conteúdo;
- a coluna acompanha a altura da área de conteúdo;
- a rolagem interna é própria, para não empurrar topbar nem rodapé.

### Acessibilidade
- é um landmark de navegação com nome acessível;
- no estado retraído, o rótulo continua disponível para leitores de tela;
- a retração é um estado visual — não deve remover destinos da árvore de acessibilidade.

### Regra de profundidade
A navegação tem **no máximo dois níveis**. Ver `[nav-item]`.

---

## [nav-item]

### Uso
Item de um dos dois níveis da `[sidebar-navigation]`.

### Composição
1. ícone (exclusivo do primeiro nível);
2. rótulo;
3. indicador de expansão, quando houver submenu.

### Aparência
- linha inteira clicável, com `radius-md`;
- primeiro nível e subnível diferem por recuo e peso tipográfico, não por cor de
  marca;
- subníveis são recuados em relação ao rótulo do item pai.

### Estados
- default;
- hover: superfície discreta (`surface-hover`) e texto em `text`;
- **ativo**: texto em `primary-text` sobre `primary-bg`, **mais** peso
  tipográfico. A cor sozinha não basta (ver Acessibilidade);
- expandido (item pai com submenu aberto);
- **indisponível**: destino ainda não implementado. Deve ser renderizado como
  texto inerte e visualmente atenuado — nunca como link quebrado.

### Interação
- o submenu abre e fecha no próprio item pai;
- o estado expandido/retraído precisa ser exposto semanticamente, e não apenas
  por rotação de ícone.

### Mobile
O mesmo item serve ao drawer: rótulo sempre visível, alvo de toque >= 44px.

### Desktop
No estado retraído o submenu não é exibido; acionar o item pai reexpande a
navegação, para que nenhum destino fique inalcançável.

### Acessibilidade
- alvo de toque mínimo de 44px;
- o item ativo não pode ser distinguível apenas por cor;
- itens indisponíveis não devem receber foco de teclado.

---

## [footer]

### Uso
Base do `[app-shell]`. Concentra informação de contexto persistente e atalhos
de ferramentas auxiliares, fora do fluxo da view corrente.

### Composição
1. informação de contexto à esquerda (ex.: data corrente);
2. grupo de gadgets à direita.

### Gadgets
Ações auxiliares de acesso rápido, apresentadas como `[icon-button]` com rótulo
visível quando houver largura.

### Aparência
- superfície `surface` (branca no contexto light);
- separação superior com `border` de 1px;
- texto em `text-muted`;
- densidade compacta, mas sem reduzir o alvo de toque.

### Estados
- os gadgets seguem os estados de `[icon-button]`;
- um gadget sem comportamento implementado **não usa aparência quebrada** para
  sinalizar isso. A borda tracejada lia como controle desabilitado e sujava o
  rodapé inteiro; o aviso de "ainda não funciona" vive no **nome acessível**
  ("… — disponível em breve"), que é onde ele alcança quem depende dele sem
  penalizar quem só olha.

### Mobile
- rótulos dos gadgets podem ser ocultados por falta de largura;
- nesse caso o nome acessível continua obrigatório;
- respeitar `safe-area-inset-bottom`.

### Desktop
- contexto e gadgets na mesma linha, alinhados às extremidades.

### Acessibilidade
- o grupo de gadgets é anunciado como grupo, com nome acessível;
- área tocável mínima de 44px;
- o rodapé não deve competir hierarquicamente com o conteúdo nem com `[page-header]`.

---

## [bottom-tab-bar]

### Uso
Padrão de navegação principal em mobile para telas mobile-first.

> O `[app-shell]` atual serve a navegação mobile por `[sidebar-navigation]` em
> modo drawer. `[bottom-tab-bar]` permanece especificado como **alternativa**
> para telas que não tenham sidebar — não é usado simultaneamente com ela.

### Estrutura
Até 5 destinos principais. No produto de hoje existem **dois**: a tela inicial
(`[home-screen]`) e Categorias — a conta fica no menu do usuário, na
`[top-navbar]`.

### Regra
Só faz sentido quando os destinos **não cabem** na `[sidebar-navigation]`. Com
dois destinos, a sidebar em modo drawer já resolve, e a barra seria peso sem
ganho.

### Aparência
- fixa na parte inferior quando usada;
- superfície elevada;
- ícone + rótulo;
- item ativo em `primary`;
- itens inativos em `text-muted`.

### Interação
- área tocável >= 44px;
- item ativo deve ser distinguível além de pequenas diferenças cromáticas.

---

## [page-header]

### Uso
Cabeçalho interno de uma tela autenticada.

### Composição
- título da página;
- descrição curta opcional;
- ação contextual opcional.

### Mobile
- título e ação podem empilhar;
- CTA de maior importância pode migrar para região inferior/floating action conforme a especificação da tela.

### Desktop
- título à esquerda;
- ação contextual à direita quando houver espaço.

---

## [empty-state]

- título curto;
- explicação objetiva;
- ilustração/ícone opcional;
- CTA quando houver próximo passo claro;
- nunca tratar ausência de dados como erro.

---

# 7. Componentes de dados financeiros

## [rubrica-picker]

### Uso
Escolher entre as rubricas do usuário. É o controle que dá acesso a todas elas.

### Variantes
- **painel (mobile)** — abre no lugar, a partir do cabeçalho da tela;
- **coluna (desktop)** — lista lateral permanente.

Mesmo componente, duas apresentações: a informação é idêntica.

### Composição da linha
- nome da rubrica;
- **um número só**: quanto **falta** pagar. Rubrica quitada diz `quitada`, sem
  valor, em `text-muted`;
- a rubrica selecionada é marcada por `primary` **e** por um indicador
  estrutural — nunca só pela cor.

### Ordem
Da **mais recente para a mais antiga**, por criação. É a mesma ordem que o
domínio usa para escolher a rubrica anterior na cópia: o topo da lista é
exatamente de onde a próxima rubrica vai copiar.

### Mobile
- fechado por padrão, ocupando uma linha no cabeçalho;
- aberto, mostra as **últimas 6** e uma ação "Ver todas";
- "Ver todas" expande **no lugar** (sem segunda camada), com altura máxima de
  ~60% da tela, rolagem interna e busca fixa na base;
- ao abrir, rola até a rubrica selecionada, para o usuário ver a vizinhança;
- tocar numa rubrica seleciona e recolhe.

### Desktop
- coluna de largura estável, com rolagem própria e busca fixa no fim;
- comporta de 8 a 12 rubricas visíveis sem rolar.

### Acessibilidade
- a lista é uma lista de seleção única, navegável por teclado;
- a rubrica selecionada é anunciada como tal, não apenas colorida.

---

## [ledger-summary]

### Uso
Situação da rubrica em três números: **total**, **pago** e **falta**.

### Composição
1. os três valores, em uma faixa;
2. `[progress-bar]` de `pago ÷ total`.

### Regra
**Não é um `[balance-card]`.** É resumo de apoio, não destaque da tela — a lista
de despesas é o conteúdo. Nada de superfície própria, sombra ou tipografia
grande: é uma faixa sobre o fundo, separada por `border`.

"Falta" é o número que o usuário procura, então recebe um pouco mais de peso —
peso relativo, não hierarquia de card.

### Tipografia
Números tabulares. Valores em `text`.

### Mobile
- uma linha, três colunas;
- ao rolar, a faixa sai e um **"Falta R$ X" compacto** reaparece ao lado do nome
  da rubrica no cabeçalho fixo.

### Desktop
Mesma faixa, com mais respiro horizontal.

---

## [progress-bar]

### Uso
Relação entre uma parte e um todo: quanto do total já foi pago.

### Aparência
- trilho em `border`/`surface-muted`, preenchimento em `primary`;
- altura fina, sem rótulo embutido.

### Semântica
Aqui **não há estado de alerta**: pagar tudo é o objetivo, e passar de 100% não
é erro. Não usar os limiares de `[budget-progress-bar]`.

### Acessibilidade
- exposta com `role="progressbar"` e `aria-valuenow`;
- nunca é a única indicação: os três números acima dizem o mesmo em texto.

---

## [expense-list]

### Uso
As despesas de uma rubrica.

### Composição
- zero ou mais `[expense-row]`;
- superfície `surface` única, com linhas separadas por `border` de 1px;
- `[empty-state]` quando a rubrica não tiver despesas.

### Regra
Não montar linha de despesa direto na tela: `[expense-row]` é o componente.

### Ação principal
O botão **Nova despesa** pertence à tela, não à lista:
- mobile — fixo na base, largura total, na zona do polegar; a lista reserva
  espaço inferior para não ficar atrás dele;
- desktop — no cabeçalho da lista.

### Ordenação
A ordem das despesas é **do usuário**, não do sistema: ele arrasta a linha para
onde quiser, e a ordem sobrevive a recarregar a página.

- a **alça** é o único ponto de arrasto. O corpo da linha abre a edição e o
  checkbox marca pago — três alvos distintos, nenhum ambíguo. Arrastar a linha
  inteira tornaria impossível acertar o toque no meio dela;
- **despesa nova entra no fim da lista**, não no topo: quem acabou de lançar
  sabe onde encontrá-la;
- **marcar pago não reordena.** A regra do `[expense-row]` continua valendo —
  linha que pula sob o dedo faz errar o toque seguinte. Só o arrasto move;
- a ordem é gravada ao soltar. Não há botão de salvar: a posição *é* o dado.

### Modos de ordenação
A lista pode ser **olhada** de três formas, num seletor "Ordenar por":

| Modo | Critério |
|---|---|
| **Minha ordem** (padrão) | a ordem que o usuário arrastou |
| **Custo** | maior valor primeiro |
| **Categoria** | ordem alfabética da categoria |

- **Minha ordem é o padrão e precisa existir.** Sem ela, escolher "Custo" uma
  vez deixaria a ordem arrastada inacessível para sempre;
- os modos calculados **não gravam nada**: são um jeito de olhar, não uma
  reordenação. Voltar para "Minha ordem" devolve exatamente o que o usuário
  arrastou;
- **a alça de arrasto some nos modos calculados.** Arrastar numa lista ordenada
  por custo não faria nada visível — a posição escolhida seria imediatamente
  desfeita pelo critério. Melhor não oferecer o gesto do que oferecê-lo em vão;
- a escolha fica na URL (`?sort=`) e a sessão lembra, para que recarregar ou
  compartilhar o link preserve o que se está vendo — mesmo padrão da rubrica
  selecionada.

### Estados
- populated;
- empty via `[empty-state]`, com CTA para criar a primeira despesa;
- reordenando: a linha em movimento se destaca, e as demais abrem espaço.

---

## [expense-row]

### Uso
Uma despesa dentro de uma rubrica.

### Composição
1. `[checkbox-toggle]` — **pago**, com alvo próprio de 44px;
2. nome (do snapshot);
3. `[category-badge]` (do snapshot);
4. valor à direita, números tabulares;
5. ações.

### Layout
- **desktop** — faixa única: checkbox, nome, chip, valor, ações;
- **mobile** — **duas** faixas: checkbox + nome + valor na primeira, chip na
  segunda. Cabe cerca do dobro de despesas na dobra em relação a três faixas.

### Ações
- **o corpo da linha abre a edição** — não é preciso acertar um ícone;
- **excluir sai da linha no mobile** e vive dentro da edição. Editar e excluir
  lado a lado, no fim de uma linha, é convite ao toque errado;
- no desktop as ações podem aparecer na linha, reveladas no hover ou no foco —
  e **sempre** alcançáveis por teclado.

### Marcar como pago
- **otimista**: a linha e o resumo mudam no mesmo quadro, antes da resposta do
  servidor; se falhar, volta e a linha mostra o erro;
- **sem confirmação e sem snackbar**: o próprio checkbox é o feedback;
- **a lista não reordena**. Linha que pula sob o dedo faz errar o toque seguinte;
- o valor e o nome continuam legíveis quando pago — muda o checkbox e, no
  máximo, a cor do nome para um cinza mais suave.

### Valor
- gasto **nunca** é vermelho. Vermelho é erro, perigo e estouro de orçamento
  (§3); uma despesa paga é o comportamento esperado, não um problema.

### Ordenação por teclado
A alça é **focável**, e as setas ↑/↓ movem a despesa uma posição. Arrastar não é
alcançável por teclado, e sem isso a função ficaria indisponível para quem não
usa mouse — a alça é o que mantém mouse, toque e teclado no mesmo controle.

- a alça tem nome acessível que diz o que ela faz, e não apenas "arrastar";
- cada movimento é anunciado em região viva: *"Internet, posição 2 de 5"*;
- nos extremos o movimento é simplesmente ignorado, sem erro nem mensagem.

### Acessibilidade
- o checkbox tem rótulo que diz **qual** despesa: "Marcar Internet como paga";
- a mudança de total é anunciada em região viva (educada).

---

## [category-badge]

### Uso
Identificação compacta da categoria.

### Aparência
- chip/badge com `radius-pill`;
- fundo na **tinta** do tom e texto na cor de **texto** do mesmo tom;
- cor proveniente da subpaleta abaixo;
- nunca gerar cor aleatória por view;
- contraste suficiente de texto/ícone.

### Subpaleta
Conjunto único de **10 tons** reutilizáveis, expostos como tokens
(`cat-<tom>-bg` / `cat-<tom>-text`). Cada tom tem duas partes: a tinta do chip e
a cor de texto correspondente, dimensionada para passar em AA **sobre essa
tinta**, não sobre branco.

| Tom | Tinta (fill) | Texto |
|---|---|---|
| `mint` | `#0FA968` | `#0B7A4A` |
| `teal` | `#0D9488` | `#0F766E` |
| `cyan` | `#0891B2` | `#0E7490` |
| `sky` | `#0284C7` | `#0369A1` |
| `blue` | `#2563EB` | `#1D4ED8` |
| `indigo` | `#4F46E5` | `#4338CA` |
| `violet` | `#7C3AED` | `#6D28D9` |
| `fuchsia` | `#A21CAF` | `#86198F` |
| `pink` | `#DB2777` | `#BE185D` |
| `slate` | `#64748B` | `#475569` |

Vermelho e âmbar ficam **fora** da subpaleta de propósito: o §3 reserva essas
duas famílias para erro/perigo e atenção. Uma categoria colorida de vermelho
passaria a ler como alerta.

### Qual tom cada categoria usa
A cor é uma **função determinística do nome** da categoria, resolvida em
`Category#color_index`. Consequências, que são o motivo da regra:

- a mesma categoria tem sempre o mesmo tom, em qualquer tela e em qualquer
  sessão — não há sorteio por renderização;
- renomear a categoria **troca** o tom;
- não existe escolha de cor pelo usuário nesta versão, e nenhuma coluna de cor
  é necessária no domínio.

### Acessibilidade
- a cor **não** é o único diferenciador: o chip sempre carrega o nome da
  categoria em texto;
- nunca usar o tom como sinal de estado (pago/pendente, erro, sucesso).

---

## [balance-card]

### Uso
Destaque do saldo total ou saldo de período.

### Composição
- label;
- valor principal;
- contexto/período opcional;
- indicador secundário opcional.

### Aparência
- superfície de destaque;
- `radius-lg`;
- valor com tipografia grande e números tabulares;
- glassmorphism apenas sutil e consistente com `[auth-card]`;
- não sacrificar contraste por transparência.

### Variantes permitidas
- `default`;
- `positive`;
- `warning` quando houver significado financeiro real.

---

## [summary-card]

### Uso
Exibir uma métrica financeira secundária: receitas, despesas, orçamento disponível ou equivalente.

### Composição
- label;
- valor;
- ícone opcional;
- comparação/legenda opcional.

### Regra
Não competir visualmente com `[balance-card]`; possui hierarquia inferior.

---

## [financial-summary-grid]

### Uso
Agrupar `[summary-card]` relacionados.

### Mobile
- uma coluna ou duas apenas quando a largura útil mantiver legibilidade.

### Desktop
- 2–4 colunas conforme quantidade de métricas.

### Gap
Usar spacing tokens.

---

## [budget-progress-bar]

### Semântica
- até 70%: normal/primary-success;
- >70% até 90%: `warning`;
- >90% até 100%: warning de alta atenção;
- >100%: `danger`.

### Acessibilidade
Percentual/estado deve ser compreensível por texto ou atributo acessível; cor sozinha não basta.

---

# 8. Feedback e overlays

## [modal]

### Uso
Container de tarefa curta que acontece **sobre** a tela, sem navegar para fora.
É onde vivem a criação/edição de despesa e a criação/renomeação de rubrica.

### Regra
Modal é **uma** apresentação responsiva, não duas telas:

- **mobile** → sobe da base (bottom sheet), com alça de arrastar;
- **desktop** → diálogo centralizado, largura fixa (~420px).

Desenhar os dois de propósito. Um diálogo centralizado encolhido não cabe no
celular, e uma folha esticada no desktop desperdiça a tela.

### Composição
1. título;
2. botão de fechar;
3. conteúdo;
4. **ação principal fixa na base**, acima do teclado.

### Mobile
- a ação principal fica na zona do polegar e permanece visível com o teclado
  aberto — é o requisito que define a altura da folha;
- o primeiro campo recebe foco ao abrir;
- o botão Voltar do sistema **fecha a folha**, em vez de sair da tela.

### Desktop
- centralizado, foco preso, `Escape` fecha, `Enter` envia;
- ao fechar, o foco volta ao elemento que abriu.

### Descarte
Agir e oferecer desfazer elimina um ponto de decisão — por isso o descarte é
**protegido**, e não uma confirmação prévia:

- **com o formulário tocado** (`dirty`), tocar no fundo **não** fecha; fechar
  exige X, `Escape` ou arrastar, e pede descarte;
- **sem tocar em nada**, tocar no fundo fecha direto.

Fechar pelo fundo é hábito, mas em formulário já preenchido ele perde dados.

---

## [snackbar]

### Uso
Mensagem temporária com uma ação. Substitui a antiga notificação de toast, que
só sabia confirmar e não sabia **desfazer** — e por isso foi removida do
sistema em vez de conviver com este componente.

### Variantes
- `info` — só a mensagem, some sozinha;
- `undo` — mensagem + ação "Desfazer"; **não** some sozinha enquanto o foco
  estiver nela.

### Regra
Ações reversíveis **agem e oferecem desfazer**, em vez de pedir confirmação
antes. Confirmação prévia fica para o que é grave e irreversível — ver
`[modal-confirm]`.

### Posição
Acima da ação principal fixa, **nunca cobrindo** o botão da base.

### Duração
A janela do desfazer precisa ser longa o bastante para ser percebida e
alcançada. Alvo inicial: ~8s.

### Acessibilidade
- anunciada em região viva;
- a ação é alcançável por teclado;
- o tempo não pode ser o único caminho: a ação precisa ser também alcançável
  pela interface normal, para quem não reage rápido.

---

## [modal-confirm]

### Uso
Confirmação de ações destrutivas ou irreversíveis.

### Composição
- título;
- consequência explícita;
- botão secundário/cancelar;
- botão danger/confirmar.

### Regra
Não usar modal para confirmações triviais que não tenham risco ou consequência relevante.

---

## [avatar]

- formato circular;
- imagem do usuário quando disponível;
- fallback com iniciais;
- fallback usa token da paleta, não cor arbitrária;
- deve funcionar em tamanhos compactos de navegação.

---

# 9. Padrões de tela

## Regra fundamental

Uma **tela também é uma especificação do Design System**.

A definição de uma tela deve informar:
- objetivo;
- composição e ordem dos componentes;
- layout mobile;
- layout desktop;
- ações principais;
- estados vazios/loading/erro quando aplicáveis;
- componentes permitidos;
- exceções explícitas.

O Claude Code deve implementar a composição especificada; não deve escolher livremente quais componentes usar quando a tela já estiver definida aqui.

---

## [auth-screen-pattern]

### Aplicável a
- login;
- cadastro;
- recuperação de senha;
- redefinição de senha;
- confirmação de conta;
- desbloqueio;
- edição de cadastro quando estiver no contexto visual de autenticação.

### Tema
`theme = dark`. Todo este padrão pertence ao contexto de autenticação e deve
permanecer escuro, em contraste deliberado com a área autenticada.

### Composição obrigatória
1. `[auth-card]`;
2. campos derivados de `[input-text]` conforme o formulário;
3. `[error-message]` quando houver erros;
4. `[button]` variante `primary` para submissão;
5. links auxiliares em hierarquia secundária.

### Layout
- página centralizada;
- sem navegação autenticada;
- foco integral na tarefa atual.

---

# 10. Especificações de telas do produto

> **Importante:** apenas telas realmente especificadas nesta seção podem ter seu layout inventariado como fechado. Se uma tarefa solicitar uma tela que não exista aqui, o Claude Code deve sinalizar a ausência da especificação antes de decidir por conta própria sua composição visual.

## [login-screen]

### Objetivo
Autenticar o usuário.

### Padrão
Usa `[auth-screen-pattern]`.

### Composição
1. `[auth-card]`;
2. título de login;
3. input de identificação conforme Devise;
4. input de senha;
5. opção de lembrar sessão quando habilitada;
6. CTA primary de entrar;
7. links secundários relevantes do Devise.

---

## [registration-screen]

### Objetivo
Criar conta.

### Padrão
Usa `[auth-screen-pattern]`.

### Composição
1. `[auth-card]`;
2. título de cadastro;
3. campos definidos pelo Devise/produto;
4. erros com `[error-message]`;
5. CTA primary;
6. links secundários.

---

## [password-recovery-screen]

### Objetivo
Solicitar recuperação de senha.

### Padrão
Usa `[auth-screen-pattern]`.

### Composição
1. `[auth-card]`;
2. título e orientação curta;
3. input de email/identificação;
4. CTA primary;
5. link de retorno ao login.

---

## [home-screen]

### Situação da especificação
**Esta tela É a raiz do app** (`home#index`). Não existe dashboard separado: ela
concentra o trabalho do dia a dia e o cadastro das duas entidades.

### Objetivo
Ver as rubricas, ver as despesas de uma rubrica, marcar o que já foi pago, e
manter o cadastro de rubricas e de despesas.

### Regra de exclusividade
**Nenhuma outra tela gerencia rubricas ou despesas.** O CRUD das duas vive aqui.
Categorias é a única outra tela de cadastro.

### Regra de navegação
**Nada aqui navega para fora.** Criar, editar e excluir acontecem sobre a
própria tela, em `[modal]`. O usuário nunca perde o contexto.

### Composição
1. `[app-shell]`;
2. `[rubrica-picker]` — painel no mobile, coluna no desktop;
3. identificação da rubrica selecionada + ações dela (`⋯`);
4. `[ledger-summary]`;
5. `[expense-list]` com `[expense-row]`;
6. ação **Nova despesa**.

#### Celular (375px)
```
│ Despesas                             (AT)│
├──────────────────────────────────────────┤
│ Janeiro 2026  ▾                        ⋯ │
├──────────────────────────────────────────┤
│  Total        Pago         Falta         │
│  2.059,80     1.850,00     209,80        │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░   │
├──────────────────────────────────────────┤
│ ☑ Escola                       1.850,00  │
│   [Comunicação]                          │
├──────────────────────────────────────────┤
│ ☐ Internet                       119,90  │
│   [Comunicação]                          │
├──────────────────────────────────────────┤
│   [        + Nova despesa        ]       │
└──────────────────────────────────────────┘
```

#### Desktop (≥ 1200px)
```
│ RUBRICAS       [+]│ Janeiro 2026  ⋯                            │
│ ▌Janeiro 26       │   Total 2.059,80  Pago 1.850,00  Falta 209,80│
│  2.059,80         │   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░   │
│ Fevereiro 26      │────────────────────────────────────────────│
│  2.059,80         │ Despesas                  [ + Nova despesa ]│
│ Viagem            │ ☑ Escola    [Comunicação]    1.850,00  ✎  × │
│  400,00           │ ☐ Internet  [Comunicação]      119,90  ✎  × │
│ [ buscar… ]       │ ☐ Telefone  [Comunicação]       89,90  ✎  × │
```

### Hierarquia
A **lista de despesas é o conteúdo**; rubricas, cabeçalho, resumo e botão são
moldura. Este é o critério para julgar qualquer ajuste: se a moldura ganhar o
mesmo peso da lista, a tela virou dashboard e está errada.

### Mobile
- coluna única;
- `[rubrica-picker]` fechado por padrão, no cabeçalho;
- ao rolar, o cabeçalho fica fixo com a rubrica e um **"Falta R$ X" compacto**;
- **Nova despesa** fixo na base, largura total, na zona do polegar;
- o rodapé **sai do fluxo fixo** para não disputar a base com o botão.

### Desktop
- `[rubrica-picker]` em coluna lateral à esquerda do conteúdo;
- detalhe à direita: identificação, resumo e lista na mesma superfície;
- a partir de **1200px**. Entre 992px e 1200px vale a apresentação do celular:
  o `[app-shell]` já ocupa 264px de navegação, e uma terceira coluna deixaria o
  detalhe com menos de 520px — estreito demais para a linha de despesa.

### Estados
- **sem rubricas** — faixa e resumo ocultos; uma frase curta explicando o que é
  uma rubrica e o botão **Criar primeira rubrica**;
- **rubrica sem despesas** — resumo zerado; `[empty-state]` no lugar da lista,
  com o mesmo botão da base e, se houver rubrica anterior, o atalho
  **Copiar despesas de "…"**;
- **todas pagas** — `Falta R$ 0,00` e barra completa. Sem comemoração;
- **muitas rubricas** — comportamento do `[rubrica-picker]`;
- **muitas despesas** — rolagem sob o cabeçalho fixo. Sem paginação enquanto não
  houver dado que a justifique;
- **erro** — mensagem curta **na própria linha** ou no campo, com
  "Tentar de novo". Nunca só um snackbar.

### Regra do primeiro uso
Nada é criado automaticamente. O nome e o período de uma rubrica são decisão do
usuário, e uma rubrica que ele não criou parece erro ou dado alheio. O ganho de
velocidade vem de **sugerir** o nome, não de criar por conta própria.

---

## [expense-modal]

### Objetivo
Criar ou editar uma despesa, **sem sair da `[home-screen]`**.

### Composição
1. `[modal]`;
2. `[input-text]` — nome;
3. `[input-currency]` — valor;
4. `[combobox]` — categoria;
5. `[error-message]` quando houver erros;
6. `[button]` `primary` — salvar (fixo na base no celular);
7. no desktop, `[button]` `secondary` — **Salvar e adicionar outra**.

### Campos
| Campo | Obrigatório | Observação |
|---|---|---|
| Nome | sim | o nome que aparecerá nas rubricas |
| Valor | sim | ≥ 0; zero é válido |
| Categoria | sim | `[combobox]`, com criação inline |

**Não existem outros campos.** Despesa é nome, valor e categoria — sem periodicidade,
sem estado, sem observação, sem data.

### Excluir
Só na edição, nunca na lista. Duas situações distintas, com nomes distintos:

- **Remover da rubrica** — age e oferece **Desfazer** (`[snackbar]` variante
  `undo`). Vale para a linha da lista e não destrói a despesa em si;
- **Excluir a despesa** — destrói o registro. Fica **dentro da edição**, mostra
  em quantas rubricas ela é usada, e é **bloqueada enquanto alguma rubrica a
  referenciar** (o histórico nunca é apagado em cascata).

> **Pendente de decisão:** se o bloqueio vale a partir de **uma** rubrica (regra
> implementada hoje) ou só a partir de **duas** (regra declarada pelo produto).
> A diferença é concreta: com "duas", excluir uma despesa usada em uma única
> rubrica apagaria junto o item daquela rubrica.

### Mobile
Sheet com a ação principal fixa acima do teclado. O primeiro campo recebe foco.

### Desktop
Diálogo centralizado, foco preso, `Escape` fecha, `Enter` envia.

### Estados
- new / edit;
- erro de validação: nome em branco, valor em branco ou negativo;
- categoria sem resultado na busca oferece **Criar "…"**.

---

## [rubrica-modal]

### Objetivo
Criar ou renomear uma rubrica.

### Composição
1. `[modal]`;
2. `[input-text]` — nome;
3. `[checkbox-toggle]` — **Copiar as despesas de "…"** (só na criação);
4. `[error-message]` quando houver erros;
5. `[button]` `primary` — criar / salvar.

### Criar
- a caixa de copiar vem **marcada** e com o nome da rubrica de origem explícito,
  para o usuário ver de onde vêm as despesas antes de aceitar;
- **sem rubrica anterior a caixa não aparece** e a rubrica nasce vazia;
- as despesas copiadas voltam **sempre como não pagas** — pagamento não se herda
  entre rubricas, e o modal diz isso;
- o campo de nome sugere o mês seguinte quando a rubrica anterior segue o padrão
  "Mês Ano"; se o nome anterior for livre ("Viagem"), vem vazio.

### Renomear
Reaproveita o mesmo modal **sem** a caixa de copiar.

### Excluir
Fica no menu `⋯` da rubrica selecionada, não no modal:
- rubrica **vazia** — age e oferece **Desfazer**;
- rubrica **com despesas** — `[modal-confirm]` dizendo **quantas** despesas vão
  junto, e depois **Desfazer**.

### Regra
Excluir uma rubrica é irreversível na percepção do usuário e leva dados junto —
por isso a confirmação prévia, ao contrário da exclusão de despesa.

### Depois de excluir
A tela seleciona a rubrica vizinha. **Nunca** fica sem seleção enquanto houver
alguma rubrica.

---

## [categories-index-screen]

### Objetivo
Visualizar e gerenciar as categorias de despesa do usuário.

### Composição
1. `[app-shell]`;
2. `[page-header]` com título "Categorias" e ação contextual "Nova categoria";
3. **lista de categorias** — uma linha por categoria;
4. `[empty-state]` no lugar da lista quando não houver nenhuma.

### A linha de categoria
1. `[category-badge]` com o nome, à esquerda;
2. ações à direita: **Editar** (`[button]` variante `secondary`) e **Excluir**
   (`[button]` variante `danger`), ambas `compact`.

- a linha é separada por `border` de 1px, não por sombra nem por card;
- a lista inteira vive numa superfície `surface` (branca), com `radius-lg`;
- **Editar** leva ao `[category-form-screen]` em modo edição.

### Exclusão
- confirmação obrigatória antes de excluir;
- a confirmação é a nativa do Turbo (`turbo_confirm`), e **não** um
  `[modal-confirm]`: o §8 reserva o modal para ações com consequência relevante,
  e excluir uma categoria vazia é trivial;
- quando a categoria tiver despesas, a exclusão é **recusada pelo domínio**. A
  tela mostra a mensagem de erro e a categoria permanece — nunca excluir em
  cascata o que está em uso.

### Mobile
- as ações descem para uma segunda linha da mesma linha de lista quando não
  couberem ao lado do badge;
- cada ação mantém alvo de toque >= 44px;
- "Nova categoria" no `[page-header]` é o CTA principal da tela.

### Desktop
- badge à esquerda e ações à direita, na mesma linha;
- a lista não se estica além da largura máxima do `[app-shell]`.

### Estados
- populated;
- empty via `[empty-state]`, com CTA para criar a primeira categoria;
- error: falha de exclusão por categoria em uso.

---

## [category-form-screen]

### Objetivo
Criar ou editar uma categoria.

### Composição
1. `[app-shell]`;
2. `[page-header]` com título "Nova categoria" ou "Editar categoria";
3. formulário com um único `[input-text]` — o nome;
4. `[error-message]` quando houver erros de validação;
5. `[button]` variante `primary` para salvar;
6. `[button]` variante `secondary` para cancelar, voltando para a lista.

### Regra
Uma tela, um assunto. A edição **não** oferece exclusão: excluir é ação da lista,
onde a consequência fica visível ao lado do que será removido.

### Mobile
- uma coluna;
- CTA de salvar em largura total;
- campos >= 44px.

### Desktop
- a largura do formulário é limitada para preservar legibilidade; não esticar o
  campo pela largura inteira da área de conteúdo.

### Estados
- new;
- edit;
- error: nome em branco, ou nome já usado pelo próprio usuário — a validação é
  case-insensitive (`Moradia` e `moradia` são a mesma categoria).

---

## [reports-screen]

### Objetivo
Apresentar visão analítica das finanças.

### Composição mínima
1. `[app-shell]`;
2. `[page-header]`;
3. filtros de período quando aplicáveis;
4. métricas com `[summary-card]`/`[financial-summary-grid]`;
5. visualizações adicionais somente após terem padrão próprio especificado neste arquivo.

### Regra
O Claude Code não deve inventar estilo de gráfico, legenda, tooltip ou paleta categórica sem uma especificação de componente correspondente neste documento.

---

# 11. Template para novo componente

Quando o produto exigir um componente ainda não especificado, adicionar primeiro uma seção seguindo este formato:

```md
## [component-name]

### Uso
Quando e por que este componente existe.

### Composição
Estrutura interna obrigatória.

### Aparência
Tokens, hierarquia visual e restrições.

### Variantes
Variantes permitidas e quando usar cada uma.

### Estados
Default, hover, focus, loading, empty, error etc., conforme aplicável.

### Mobile
Comportamento em 375px.

### Desktop
Comportamento em 1280px.

### Acessibilidade
Regras específicas.
```

---

# 12. Template para nova tela

```md
## [screen-name]

### Objetivo
O que o usuário realiza nesta tela.

### Composição
1. componente A;
2. componente B;
3. componente C.

### Mobile
Composição e comportamento em 375px.

### Desktop
Composição e comportamento em 1280px.

### Ações principais
Quais ações existem e sua hierarquia.

### Estados
- loading;
- populated;
- empty;
- error.

### Regras específicas
Exceções ou restrições da tela.
```

---

# 13. Regra de alteração do Design System

Este arquivo **não é atualizado porque código foi criado**.

Ele só deve mudar quando houver uma decisão de design, por exemplo:
- novo componente;
- nova tela;
- nova variante;
- mudança de comportamento responsivo;
- mudança de token;
- mudança de composição de uma tela;
- depreciação conceitual de um padrão.

Estado de implementação e caminhos de arquivos pertencem ao `COMPONENT-REGISTRY.md`.
