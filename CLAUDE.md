# CLAUDE.md

## Identidade do projeto

App de controle de despesas pessoais em Rails 8, autenticação via Devise, frontend em Bootstrap.

Dark mode é o tema visual padrão.

A governança de UI do projeto é dividida em três responsabilidades:

- `DESIGN-SYSTEM.md` define **como a interface deve ser**.
- `COMPONENT-REGISTRY.md` registra **o que já foi implementado e onde está**.
- `CLAUDE.md` define **como o Claude Code deve trabalhar usando esses dois arquivos**.

Essas responsabilidades não devem ser misturadas.

---

# Regra mandatória número 1: DESIGN-SYSTEM.md é a única fonte de verdade visual

Antes de escrever qualquer HTML, ERB, CSS/SCSS, JavaScript, Stimulus ou qualquer código relacionado à interface, você **deve consultar o `DESIGN-SYSTEM.md`**.

O `DESIGN-SYSTEM.md` define:

- foundations;
- cores;
- tipografia;
- espaçamentos;
- bordas;
- elevação;
- componentes;
- variantes;
- estados;
- padrões de interação;
- comportamento responsivo;
- composição das telas.

Nunca invente silenciosamente uma solução visual que deveria estar definida no Design System.

Se uma tela estiver especificada no `DESIGN-SYSTEM.md`, sua estrutura deve seguir essa especificação.

Se um componente estiver especificado no `DESIGN-SYSTEM.md`, sua implementação deve seguir essa especificação.

---

# Regra mandatória número 2: fluxo obrigatório ao construir uma tela

Sempre que a tarefa envolver construir, alterar ou completar uma tela:

1. Identifique qual tela está sendo trabalhada.

2. Localize a especificação correspondente no `DESIGN-SYSTEM.md`.

3. Leia completamente a especificação da tela, incluindo:
   - objetivo;
   - estrutura;
   - hierarquia;
   - componentes utilizados;
   - layout;
   - comportamento mobile;
   - comportamento desktop;
   - estados;
   - variantes;
   - padrões de interação.

4. Extraia a lista de componentes necessários para montar a tela.

5. Para **cada componente necessário**, localize e leia sua especificação correspondente no `DESIGN-SYSTEM.md`.

6. Depois de compreender como o componente deve ser, consulte o `COMPONENT-REGISTRY.md` para descobrir se ele já possui implementação no projeto.

7. Somente depois dessas verificações comece a implementação.

A composição da tela não deve ser decidida livremente se já existir especificação no `DESIGN-SYSTEM.md`.

---

# Regra mandatória número 3: DESIGN-SYSTEM.md define; COMPONENT-REGISTRY.md localiza

Nunca use o `DESIGN-SYSTEM.md` para descobrir se determinado componente já foi implementado.

Essa responsabilidade pertence exclusivamente ao `COMPONENT-REGISTRY.md`.

Fluxo correto:

```text
preciso do componente
        ↓
DESIGN-SYSTEM.md
        ↓
como esse componente deve funcionar e parecer?
        ↓
COMPONENT-REGISTRY.md
        ↓
já existe implementação?
```

O Design System é normativo.

O Registry é operacional.

---

# Regra mandatória número 4: reutilizar antes de criar

Depois de localizar a especificação do componente no `DESIGN-SYSTEM.md`, consulte o `COMPONENT-REGISTRY.md`.

## Se o componente estiver implementado

Reutilize a implementação existente.

Nunca recrie a mesma responsabilidade visual em outro arquivo.

Nunca copie o código de um componente reutilizável diretamente para uma view.

Prefira:

- partials;
- helpers;
- classes compartilhadas;
- variantes;
- parâmetros;
- componentes já existentes.

Se houver necessidade de uma pequena diferença de conteúdo ou comportamento, adapte o componente existente por meio de sua API, variante ou parâmetros.

Não crie uma segunda implementação apenas porque a nova tela apresenta uma pequena diferença.

---

## Se o componente estiver parcialmente implementado

Inspecione os arquivos registrados.

Complete ou adapte a implementação existente seguindo a especificação do `DESIGN-SYSTEM.md`.

Não abandone a implementação existente para criar outra paralela.

Depois da alteração, atualize o `COMPONENT-REGISTRY.md`.

---

## Se o componente ainda não estiver implementado

Implemente o componente seguindo integralmente sua especificação no `DESIGN-SYSTEM.md`.

Depois da implementação:

1. registre o componente no `COMPONENT-REGISTRY.md`;
2. informe os arquivos que materializam o componente;
3. registre seu estado real de implementação.

Não altere o `DESIGN-SYSTEM.md` apenas porque o componente passou a existir no código.

---

# Regra mandatória número 5: nunca duplicar componentes

Antes de criar qualquer implementação nova, verifique se a mesma responsabilidade visual já existe no projeto.

Faça a pergunta:

> "Já existe algum componente no Registry ou no projeto que desempenha esta mesma responsabilidade?"

Se a resposta for sim:

- reutilize;
- estenda;
- adicione uma variante;
- adicione parâmetros;
- consolide.

Nunca mantenha duas implementações concorrentes para a mesma responsabilidade visual.

Exemplos proibidos:

```text
_balance_card.html.erb
_month_balance_card.html.erb
_dashboard_balance_card.html.erb
```

se os três representam essencialmente o mesmo componente.

O correto seria existir um único componente com parâmetros ou variantes apropriadas.

---

# Regra mandatória número 6: variante não é automaticamente um novo componente

Não crie componentes separados apenas porque há variações visuais ou comportamentais simples.

Exemplo:

```text
button
├── primary
├── secondary
├── danger
└── loading
```

Esses elementos pertencem ao mesmo componente `button`, salvo quando o `DESIGN-SYSTEM.md` determinar explicitamente o contrário.

O mesmo princípio vale para:

- cards;
- badges;
- inputs;
- alerts;
- modais;
- tabelas;
- navegação;
- estados de componentes.

Antes de criar um novo componente, verifique se a necessidade pode ser resolvida como variante de um componente já existente.

---

# Regra mandatória número 7: um componente pode possuir vários arquivos

"Um componente" significa uma responsabilidade visual única.

Isso não significa necessariamente um único arquivo físico.

Um componente pode ser materializado por vários arquivos quando necessário.

Exemplo:

```text
balance-card
├── app/views/shared/_balance_card.html.erb
├── app/assets/stylesheets/design_system/components/_balance_card.scss
├── app/javascript/controllers/balance_card_controller.js
└── test/...
```

Todos esses arquivos pertencem ao mesmo componente.

O `COMPONENT-REGISTRY.md` deve registrar os arquivos associados à implementação.

Não espalhe estilos ou comportamento de um componente por arquivos não relacionados sem necessidade.

---

# Regra mandatória número 8: não inventar UI silenciosamente

Se uma tarefa exigir uma tela ou componente cuja especificação não exista ou esteja incompleta no `DESIGN-SYSTEM.md`, não tome decisões visuais arbitrárias silenciosamente.

Primeiro:

1. identifique exatamente o que está faltando;
2. informe a ausência da especificação;
3. use os foundations, componentes e padrões já existentes para propor a solução mais consistente possível;
4. se uma nova definição visual precisar entrar permanentemente no sistema, atualize o `DESIGN-SYSTEM.md`.

Mudanças no Design System devem representar decisões de design reais.

Nunca altere o Design System apenas para registrar implementação.

---

# Regra mandatória número 9: foundations são obrigatórios

Todo código visual deve utilizar os foundations definidos no `DESIGN-SYSTEM.md`.

Isso inclui, quando aplicável:

- cores;
- tipografia;
- spacing;
- radius;
- borders;
- elevation;
- breakpoints;
- motion.

Evite valores visuais arbitrários diretamente nos componentes quando já existir token correspondente.

Exemplo:

Evite:

```css
padding: 17px;
color: #0fa968;
border-radius: 9px;
```

quando o Design System possuir tokens apropriados.

Prefira utilizar os tokens definidos pelo sistema.

---

# Regra mandatória número 10: dark mode é o padrão

Dark mode é o tema padrão da aplicação.

Todo componente novo ou alterado deve funcionar corretamente no tema padrão e nas variações previstas no `DESIGN-SYSTEM.md`.

Não escreva cores diretamente assumindo um único fundo.

Use tokens semânticos sempre que possível.

O tema light, quando previsto, deve utilizar os mesmos componentes e a mesma estrutura, alterando apenas os tokens apropriados.

---

# Regra mandatória número 11: mobile-first

Toda interface deve ser construída mobile-first.

Referência principal:

```text
375px
```

Depois adapte progressivamente para telas maiores.

Também valide o comportamento em desktop, tomando como referência:

```text
1280px
```

Não construa primeiro a versão desktop para depois tentar "encaixar" em mobile.

Elementos de interação devem respeitar:

- legibilidade;
- hierarquia;
- área de toque adequada;
- espaçamento;
- thumb reach quando aplicável.

Área tocável mínima:

```text
44px
```

---

# Regra mandatória número 12: Bootstrap é infraestrutura, não fonte de design

Bootstrap faz parte da stack e pode ser utilizado para:

- grid;
- utilities;
- comportamento;
- acessibilidade;
- componentes estruturais úteis.

Porém, Bootstrap não substitui o `DESIGN-SYSTEM.md`.

Se Bootstrap fornecer um componente cuja aparência padrão diverge da especificação do Design System:

1. reutilize a estrutura/comportamento do Bootstrap quando útil;
2. aplique o estilo definido pelo Design System.

Não invente uma estética "Bootstrap padrão" apenas porque o framework já possui determinado componente.

---

# Regra mandatória número 13: feedback visível durante tarefas de UI

Durante qualquer tarefa que envolva interface, layout, componentes visuais ou telas, **não trabalhe silenciosamente**.

O usuário deve conseguir acompanhar na tela como o `DESIGN-SYSTEM.md` e o `COMPONENT-REGISTRY.md` estão sendo utilizados.

O feedback deve acompanhar o progresso real da tarefa.

Sempre que aplicável, informe:

1. qual tela ou elemento de UI está sendo trabalhado;
2. qual especificação da tela foi localizada no `DESIGN-SYSTEM.md`;
3. quais componentes a especificação exige;
4. qual componente está sendo analisado naquele momento;
5. qual especificação do componente foi encontrada no `DESIGN-SYSTEM.md`;
6. qual resultado foi encontrado no `COMPONENT-REGISTRY.md`;
7. qual decisão foi tomada:
   - reutilizar;
   - ajustar;
   - criar;
8. qual arquivo existente será reutilizado ou alterado;
9. quando um componente novo estiver sendo construído;
10. quando um componente for integrado à tela;
11. quando o `COMPONENT-REGISTRY.md` for atualizado.

O feedback deve ser curto e útil.

Não transforme o terminal em um log excessivamente verboso.

Exemplo de comportamento esperado:

```text
[Design System] Implementando tela: transactions/index

[Design System] Especificação da tela encontrada.
Componentes necessários:
- app-shell
- top-navbar
- page-header
- transaction-list
- bottom-tab-bar

[Design System] Analisando: top-navbar
Especificação localizada.

[Component Registry] top-navbar já está implementado.
Reutilizando:
app/views/shared/_top_navbar.html.erb

[Design System] Analisando: transaction-list
Especificação localizada.
Estados previstos:
- populated
- empty

[Component Registry] transaction-list ainda não possui implementação.

[Design System] Criando transaction-list conforme sua especificação.

[UI] transaction-list integrado em transactions/index.

[Registry] Registrando implementação de transaction-list.

[UI] Tela concluída conforme composição definida no Design System.
```

### Regras do feedback

Não informe apenas:

```text
Consultei o Design System.
```

Informe **o que foi consultado e qual decisão resultou dessa consulta**.

Nunca anuncie uma etapa como concluída antes de executá-la.

Sempre que reutilizar um componente existente, mostre:

- nome;
- caminho relevante.

Sempre que criar um componente, informe explicitamente:

```text
Criando <componente> conforme a especificação do DESIGN-SYSTEM.md.
```

Se houver ausência ou ambiguidade de especificação, informe isso claramente.

---

# Regra mandatória número 14: COMPONENT-REGISTRY.md deve refletir o código real

O `COMPONENT-REGISTRY.md` não é uma lista de intenção.

Ele deve representar o estado real do projeto.

Não marque um componente como implementado antes de existir implementação funcional.

Sempre que:

- criar;
- remover;
- substituir;
- consolidar;
- mover;
- alterar significativamente

um componente, atualize o Registry na mesma tarefa.

Os caminhos registrados devem corresponder aos arquivos reais.

---

# Regra mandatória número 15: DESIGN-SYSTEM.md não é changelog de implementação

Não adicione ao `DESIGN-SYSTEM.md` informações como:

- "implementado";
- "feito";
- "done";
- caminho de arquivo;
- data da implementação;
- view que atualmente utiliza o componente.

Essas informações pertencem ao `COMPONENT-REGISTRY.md` ou ao histórico do Git.

O `DESIGN-SYSTEM.md` deve continuar respondendo:

> Como a interface deve ser?

e não:

> O que já foi programado?

---

# Checklist obrigatório antes de concluir uma tarefa de UI

Antes de declarar qualquer tarefa de UI como concluída, confirme:

## Tela

- A especificação da tela foi localizada no `DESIGN-SYSTEM.md`?
- A composição implementada corresponde à composição definida?
- Todos os componentes obrigatórios foram considerados?
- Estados relevantes foram implementados?

## Componentes

- A especificação de cada componente foi consultada no `DESIGN-SYSTEM.md`?
- O `COMPONENT-REGISTRY.md` foi consultado antes de criar qualquer componente?
- Componentes existentes foram reutilizados?
- Alguma implementação paralela ou duplicada foi criada?
- Variantes foram tratadas como variantes quando apropriado?

## Visual

- Foram utilizados os tokens/foundations previstos?
- Dark mode está correto?
- A interface foi construída mobile-first?
- Foi validada em aproximadamente 375px?
- Foi validada em aproximadamente 1280px?
- As áreas tocáveis respeitam o mínimo de 44px quando aplicável?

## Registry

- Componentes novos foram registrados?
- Componentes alterados tiveram seus registros atualizados?
- Caminhos registrados correspondem aos arquivos reais?
- O Registry representa o estado real do código após a tarefa?

## Feedback

- O progresso de utilização do Design System foi mostrado durante a execução?
- Foi informado o que foi reutilizado?
- Foi informado o que foi criado ou alterado?

Se qualquer item obrigatório estiver incorreto ou não verificado, a tarefa ainda não está concluída.

Corrija antes de reportar sucesso.

---

# Resumo obrigatório ao finalizar tarefa de UI

Ao concluir uma tarefa de UI, apresente um resumo curto contendo:

```text
Design System
- tela utilizada:
- componentes consultados:

Reutilizado
- componente → caminho

Criado
- componente → arquivos

Alterado
- componente → arquivos

Registry
- atualizações realizadas:

Validação
- mobile:
- desktop:
- dark mode:
```

Não precisa listar uma categoria vazia.

O resumo deve representar apenas o que realmente aconteceu.

---

# Stack de referência

- Rails 8
- Ruby
- ERB
- Devise
- Bootstrap
- SCSS/CSS
- Hotwire
- Turbo
- Stimulus

Arquivos de governança de UI:

```text
DESIGN-SYSTEM.md
COMPONENT-REGISTRY.md
CLAUDE.md
```

Hierarquia de responsabilidade:

```text
DESIGN-SYSTEM.md
→ define como deve ser

COMPONENT-REGISTRY.md
→ informa o que existe e onde está

CLAUDE.md
→ obriga o processo correto de consulta, reutilização e implementação
```
