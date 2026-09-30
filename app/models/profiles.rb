# Perfis do app.
#
# Lista FECHADA e hardcoded de propósito: qual perfil existe é decisão de
# código, não um dado que se cria à vontade no banco. Quem tem qual perfil é
# outra coisa, e essa mora nas tabelas do rolify.
#
# As duas NÃO se confundem: o rolify tem `remove_role_if_empty = true` por
# padrão, então quando o último portador perde o perfil a linha de `roles` é
# APAGADA. A tabela guarda vínculos, não o catálogo — buscar ali "quais perfis
# existem" devolve nil de forma intermitente. É por isso que este módulo é
# separado do model `Role`: a dependência corre numa direção só, `Role` ->
# `Profiles`, e nunca o contrário.
module Profiles
  ADMIN = :admin

  # Em Symbol, que é como se PERGUNTA ao rolify: `user.has_role?(:admin)`.
  ALL = [ ADMIN ].freeze

  # Em String, que é como o rolify GRAVA e devolve. É contra esta lista que a
  # validação do `Role` compara — `inclusion: { in: ALL }` rejeitaria tudo, já
  # que o valor do banco nunca é Symbol.
  NAMES = ALL.map(&:to_s).freeze

  # Aceita Symbol ou String e responde sobre o vocabulário, sem tocar no banco.
  def self.known?(name)
    ALL.include?(name.to_s.to_sym)
  end
end
