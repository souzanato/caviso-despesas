# O vínculo entre usuário e perfil, na forma que o rolify espera.
#
# Esta tabela guarda QUEM tem qual perfil. QUAIS perfis existem é outra coisa,
# e mora em `Profiles` — ver o comentário lá para o motivo (o rolify apaga a
# linha quando o último portador perde o perfil, então isto aqui não serve como
# catálogo).
class Role < ApplicationRecord
  has_and_belongs_to_many :users, join_table: :users_roles

  belongs_to :resource, polymorphic: true, optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  # A lista é FECHADA no nível do modelo: `user.add_role(:qualquer_coisa)`
  # levanta RecordInvalid em vez de gravar um perfil que ninguém sabe checar.
  #
  # Contra `NAMES` (String) e não contra `ALL` (Symbol): o rolify grava o nome
  # como String, então a comparação com Symbols rejeitaria tudo, inclusive o
  # `:admin` legítimo.
  validates :name, presence: true, inclusion: { in: Profiles::NAMES }

  scopify
end
