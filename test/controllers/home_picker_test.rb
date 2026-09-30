require "test_helper"

# [rubrica-picker] §7 — a estrutura de que o `picker_controller.js` depende.
#
# O seletor de rubricas é feito de três arquivos que precisam concordar sobre a
# MESMA estrutura: a view emite os alvos, o Stimulus os consome pelo nome, e o
# CSS posiciona por classe. Quando um dos três muda sozinho, nada quebra no
# boot — quebra na mão do usuário, e foi o que aconteceu: o CSS fechava o painel
# por uma classe que o JS tinha deixado de aplicar, e a lista não abria no
# celular. Estes testes prendem o contrato pelo lado que dá para prender.
class HomePickerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:renato)
    # O gate do app exige perfil; sem isto o teste bate na tela de bloqueio.
    @user.add_role(Profiles::ADMIN)
    @ledger = @user.ledgers.create!(name: "Janeiro 2026")
    @outra = @user.ledgers.create!(name: "Viagem São Paulo")
  end

  def documento
    Nokogiri::HTML(response.body)
  end

  test "o painel carrega o id que o botão do título anuncia em aria-controls" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    alvo = documento.at_css("button.ds-titlebar__toggle")["aria-controls"]

    # Um `aria-controls` que aponta para o vazio não quebra a tela, só mente
    # para quem usa leitor de tela — por isso o id tem de existir de fato.
    assert_not_nil documento.at_css("##{alvo}"), "aria-controls aponta para ##{alvo}, que não existe"
  end

  test "cada rubrica carrega o nome que o filtro lê" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    nomes = documento.css('.ds-picker__list [data-picker-target="option"]').map { |no| no["data-picker-name"] }

    assert_includes nomes, "Janeiro 2026"
    assert_includes nomes, "Viagem São Paulo"
    assert_equal nomes.size, nomes.compact.size, "há opção sem data-picker-name — o filtro a esconderia sempre"
  end

  test "a busca é irmã do corpo rolável, e não filha" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    busca = documento.at_css(".ds-picker__search")
    corpo = documento.at_css(".ds-picker__body")

    assert_not_nil busca, "o painel não tem busca"
    assert_not_nil corpo

    # A §7 pede "busca fixa na base". Dentro do contêiner que rola ela sairia de
    # vista na primeira rolagem, que é quando mais serve — por isso a posição no
    # DOM é o que a mantém presa, e é isso que este teste protege.
    #
    # Pelo CSS descendente, e não comparando os nós: `assert_not_includes` usa
    # `==`, e dois nós Nokogiri que apontam para o mesmo elemento não são iguais
    # por ali — a asserção passaria com a busca dentro do corpo.
    assert_empty corpo.css(".ds-picker__search"),
                 "a busca está dentro do corpo rolável; ela precisa ser irmã, para ficar fixa na base"
    assert_equal "search", busca.at_css("input")["type"]
    assert busca.at_css("input")["aria-label"].present?, "campo de busca sem nome acessível"
  end

  test "a ação Nova rubrica fica fora do corpo rolável" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    corpo = documento.at_css(".ds-picker__body")
    cabecalho = documento.at_css(".ds-picker__head")

    # Mesmo motivo da busca: presa ao rodapé do painel, não ao fim da lista.
    assert_empty corpo.css(".ds-picker__new"), "a ação está dentro do corpo rolável"
    assert_equal 1, cabecalho.css(".ds-picker__new").size

    # Uma ação só, em duas apresentações (ícone no celular, botão largo no
    # desktop). Duas — uma por largura — seriam a implementação paralela que a
    # Regra 5 proíbe, e a segunda só apareceria no breakpoint errado.
    assert_equal 1, documento.css(".ds-picker__new").size
    assert_equal "Nova rubrica", cabecalho.at_css(".ds-picker__new")["aria-label"]
  end

  test "o recorte de recentes fica no JS, não no servidor" do
    sign_in @user
    # Mais que o limite, seja ele qual for: com menos, "veio tudo" e "veio o
    # recorte" seriam indistinguíveis, e o teste passaria sem provar nada.
    20.times { |i| @user.ledgers.create!(name: "Extra #{i}") }

    get root_path(ledger: @ledger.id)

    # As rubricas vêm TODAS no HTML — o JS é quem decide quais aparecem, porque
    # a busca precisa poder alcançar qualquer uma delas sem ida ao servidor.
    # Um recorte aqui deixaria a busca incapaz de achar as que ficaram de fora.
    assert_equal @user.ledgers.count, documento.css('.ds-picker__list [data-picker-target="option"]').size
    assert_operator @user.ledgers.count, :>, 12
  end

  test "o backdrop é irmão do painel, e não filho" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    backdrop = documento.at_css(".ds-picker__backdrop")
    painel = documento.at_css(".ds-picker__panel")

    assert_not_nil backdrop, "o painel não tem backdrop"
    # Dentro do painel, o `overflow: hidden` da folha o recortaria — e ele
    # precisa cobrir a tela inteira, não só a folha.
    assert_empty painel.css(".ds-picker__backdrop"), "o backdrop está dentro do painel"
    # `key?` e não `["hidden"].present?`: atributo booleano sem valor vira `""`
    # no Nokogiri, e `"".present?` é falso — o teste passaria a afirmar o
    # contrário do que quer.
    assert backdrop.key?("hidden"), "o backdrop nasce escondido"
  end

  test "a busca aparece com qualquer quantidade de rubricas" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    # Sem condição no servidor: filtrar serve em qualquer tamanho de lista, e
    # uma busca que só existe às vezes obriga o usuário a descobrir em quais
    # telas ela está. Havia um corte em "mais de 6 rubricas" que saiu.
    assert_not_nil documento.at_css(".ds-picker__search input"), "a busca sumiu com poucas rubricas"
    assert_equal 1, documento.css(".ds-picker__search").size, "busca duplicada no painel"

    # O título que ocupava o lugar dela também saiu.
    assert_nil documento.at_css(".ds-picker__title")
  end

  test "o limite de recentes vem do markup, e não de uma constante no JS" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    # Um número só, e no lugar onde quem decide o produto olha. Duas fontes —
    # atributo e constante — divergiriam na primeira vez que alguém mudasse uma.
    limite = documento.at_css("[data-picker-limit-value]")["data-picker-limit-value"]

    assert_equal "12", limite
  end

  test "o botão de limpar nasce escondido e dentro do campo" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    limpar = documento.at_css(".ds-picker__clear")

    assert_not_nil limpar, "o painel não tem botão de limpar"
    # Dentro do campo: é o gesto que o usuário já conhece de qualquer busca.
    assert_not_nil documento.at_css(".ds-picker__search .ds-picker__clear")
    # Sem texto não há o que limpar; o JS o revela ao digitar.
    assert limpar.key?("hidden"), "o botão de limpar nasce visível"
    assert limpar["aria-label"].present?, "botão de limpar sem nome acessível"
  end

  test "o campo de busca pede teclado e tecla de busca no celular" do
    sign_in @user

    get root_path(ledger: @ledger.id)

    campo = documento.at_css(".ds-picker__search input")

    # `inputmode` e `enterkeyhint` são o que faz o teclado móvel abrir com a
    # tecla certa, em vez do teclado alfabético com "return".
    assert_equal "search", campo["type"]
    assert_equal "search", campo["inputmode"]
    assert_equal "search", campo["enterkeyhint"]
    assert_equal "off", campo["autocomplete"]
  end
end
