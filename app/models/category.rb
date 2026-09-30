# Categoria de despesa. Agrupa o cadastro permanente de despesas.
class Category < ApplicationRecord
  # Lista inicial do produto. Vive aqui (e não em db/seeds.rb) para poder ser
  # reusada por qualquer fluxo que precise provisionar um usuário novo, sem
  # duplicar a constante.
  DEFAULTS = [
    "Moradia",
    "Alimentação",
    "Educação",
    "Saúde",
    "Transporte",
    "Comunicação",
    "Assinaturas e Serviços",
    "Lazer",
    "Seguros",
    "Impostos e Taxas",
    "Cuidados Pessoais",
    "Pets",
    "Filhos",
    "Dívidas e Financiamentos",
    "Outros"
  ].freeze

  # Tons do [category-badge] (§7). A ORDEM é o que dá estabilidade à cor: mudar
  # a ordem troca o tom de todas as categorias já existentes.
  COLOR_TONES = %w[mint teal cyan sky blue indigo violet fuchsia pink slate].freeze

  belongs_to :user

  # Sem `dependent: :destroy`: despesa é cadastro permanente e apagar a
  # categoria levaria junto histórico que não pertence a ela. Bloqueia e
  # devolve erro, para a decisão ser explícita de quem chamou.
  has_many :expenses, dependent: :restrict_with_error

  before_validation :normalize_name

  validates :name, presence: true
  # Unicidade por usuário, sem diferenciar maiúsculas: "Moradia" e "moradia"
  # são a mesma categoria. O banco reforça com índice funcional.
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }

  # Idempotente e seguro contra variação de caixa: se o usuário já tem
  # "moradia", não cria "Moradia" ao lado.
  def self.seed_defaults_for!(user)
    DEFAULTS.each do |name|
      next if user.categories.where("lower(name) = ?", name.downcase).exists?

      user.categories.create!(name: name)
    end
  end

  # Índice do tom do chip, derivado do nome (§7).
  #
  # Usa MD5, e NÃO `String#hash`: o hash nativo do Ruby é semeado por processo,
  # então a cor de cada categoria mudaria a cada reinício do servidor. Este
  # caminho dá sempre o mesmo inteiro para o mesmo nome.
  #
  # Consequência assumida e documentada: renomear a categoria troca a cor.
  def color_index
    self.class.color_index_for(name)
  end

  # Nome do tom, usado como sufixo da classe do chip. A view nunca decide cor —
  # ela só repassa isto.
  def color_tone
    self.class.color_tone_for(name)
  end

  # Versões por NOME, não por registro. Existem porque o chip de uma rubrica
  # exibe o snapshot do nome da categoria, e a cor precisa acompanhar o que
  # está na tela: se a categoria for renomeada depois, a rubrica antiga segue
  # mostrando o nome E a cor da época.
  def self.color_index_for(name)
    Digest::MD5.digest(name.to_s.downcase).unpack1("N") % COLOR_TONES.size
  end

  def self.color_tone_for(name)
    COLOR_TONES[color_index_for(name)]
  end

  private

  # `squish` remove espaço nas pontas e colapsa espaço interno, que é a fonte
  # mais comum de duplicata invisível ("Moradia " vs "Moradia").
  def normalize_name
    self.name = name.squish if name.present?
  end
end
