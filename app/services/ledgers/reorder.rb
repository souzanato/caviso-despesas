# Regrava a posição das despesas de uma rubrica.
#
# Recebe a lista de ids na ordem desejada e reescreve as posições numa única
# transação — o cliente manda o estado final, não uma sequência de passos.
#
# Ids desconhecidos são **ignorados**, e ids que o cliente não mandou continuam
# no fim, na ordem relativa anterior. Isso torna a operação tolerante a uma
# lista desatualizada (duas abas abertas, por exemplo) em vez de corromper a
# ordem por causa de uma corrida.
module Ledgers
  class Reorder
    def self.call(ledger:, ids:)
      new(ledger:, ids:).call
    end

    def initialize(ledger:, ids:)
      @ledger = ledger
      @ids = Array(ids).map(&:to_i)
    end

    def call
      # Só o que pertence a ESTA rubrica entra na conta: um id de outra conta
      # não deve nem ser considerado.
      atuais = ledger.ledger_items.pluck(:id)
      ordem = ids.uniq.select { |id| atuais.include?(id) }
      faltando = atuais - ordem

      LedgerItem.transaction do
        (ordem + faltando).each_with_index do |id, indice|
          # `update_all` não dispara callbacks nem validações — é o que se quer
          # aqui: regravar posição não é uma mudança de negócio.
          ledger.ledger_items.where(id: id).update_all(position: indice + 1)
        end
      end
    end

    private

    attr_reader :ledger, :ids
  end
end
