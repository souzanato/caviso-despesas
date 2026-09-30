require "test_helper"

# Guarda contra uma armadilha de ERB que já mordeu duas vezes neste projeto.
#
# Um comentário ERB não pode conter outro delimitador ERB dentro dele: o
# primeiro `%>` interno FECHA o comentário, e todo o texto depois dele vaza
# como HTML na página. Foi assim que um parágrafo inteiro de comentário
# apareceu escrito na tela, e o aviso já existia em sessions/new.html.erb.
#
# O teste lê os arquivos-fonte de propósito: é uma verificação estática, e o
# defeito não aparece em nenhum assert de conteúdo renderizado — ele some no
# meio do HTML, como texto solto.
class ErbCommentsTest < ActiveSupport::TestCase
  test "nenhum comentário ERB contém outro delimitador ERB" do
    infratores = []

    Dir[Rails.root.join("app/views/**/*.erb")].sort.each do |caminho|
      fonte = File.read(caminho)
      relativo = caminho.sub("#{Rails.root}/", "")

      fonte.scan(/<%#(.*?)%>/m) do |(corpo)|
        next unless corpo.include?("<%")

        linha = fonte[0...fonte.index(corpo)].count("\n") + 1
        infratores << "#{relativo}:#{linha}"
      end
    end

    assert_empty infratores,
                 "comentário ERB com delimitador interno — o texto depois dele vaza na página: " \
                 "#{infratores.join(', ')}"
  end
end
