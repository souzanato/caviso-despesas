class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # ---------------------------------------------------------------------------
  # Dados do domínio. Todos escopados por usuário — nada é global.
  # ---------------------------------------------------------------------------
  #
  # A ORDEM DE DECLARAÇÃO IMPORTA e não é estética. `User#destroy` (usado pelo
  # cancelamento de conta do Devise) roda as associações na ordem em que estão
  # escritas aqui.
  #
  # As rubricas precisam sair PRIMEIRO: `Expense` tem `restrict_with_error` em
  # ledger_items e a FK do banco também bloqueia, então enquanto existir um
  # LedgerItem apontando para uma despesa, aquela despesa não pode ser apagada.
  # Com as rubricas (e seus itens) destruídas antes, as despesas saem limpas e
  # só então as categorias. Reordenar estas três linhas quebra o cancelamento de
  # conta — test/models/user_test.rb cobre isso.
  has_many :ledgers, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :categories, dependent: :destroy

  validates :full_name, presence: true
  # A mensagem do formato vem de activemodel.errors.models.user.attributes.username
  # (config/locales/auth.pt-BR.yml), já que o validador :format usa a chave :invalid.
  validates :username,
            presence: true,
            format: { with: /\A[a-zA-Z0-9._-]+\z/ },
            uniqueness: { case_sensitive: false }

  # Localiza ou cria o usuário a partir dos dados devolvidos pelo Google.
  # Se o e-mail já estiver cadastrado, reaproveita a conta existente em vez
  # de criar uma duplicada, apenas vinculando a conta do provedor.
  def self.from_omniauth(auth)
    email = auth.info.email.to_s.downcase

    user = find_by(email: email) || new(email: email)
    user.provider ||= auth.provider
    user.uid ||= auth.uid
    user.full_name = auth.info.name if user.full_name.blank?
    user.username = generate_username(auth.info) if user.username.blank?

    if user.new_record?
      user.password = Devise.friendly_token[0, 20]
    else
      # Conta já existente: só grava se algo mudou (ex.: vinculação do provedor).
      return user unless user.changed?
    end

    user.save
    user
  end

  # Usuário criado via Google não possui senha definida.
  def password_required?
    super && provider.blank?
  end

  def self.generate_username(info)
    base = info.email.to_s.split("@").first.to_s
    base = info.name.to_s.parameterize(separator: "") if base.blank?
    base = base.parameterize(separator: "")[0, 30]
    base = "user" if base.blank?

    username = base
    suffix = 1
    while exists?(username: username)
      username = "#{base}#{suffix}"
      suffix += 1
    end

    username
  end
  private_class_method :generate_username
end
