ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Fixtures cobrem só as pré-condições estáveis: usuários e categorias.
    #
    # Despesas, rubricas e itens são construídos dentro de cada teste. Não é
    # preferência de estilo: os cenários de snapshot dependem de controlar
    # exatamente o que foi criado, com que valor, e em que ordem — um fixture
    # compartilhado esconderia justamente o que o teste precisa observar.
    fixtures :all

    # Sem paralelização de propósito: a suíte é pequena, e ordem determinística
    # importa mais aqui do que o tempo economizado.
  end
end

# `sign_in` / `sign_out` para os testes de controller, que passam pela
# autenticação do Devise de verdade em vez de burlarem o before_action.
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
