# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Categorias iniciais do domínio financeiro.
#
# A lista é POR USUÁRIO — o domínio é escopado por conta, não global — então as
# seeds provisionam as categorias padrão para cada usuário que já existe.
#
# Idempotente: rodar `db:seed` várias vezes não duplica nada, e uma categoria
# que o usuário já tenha (mesmo com caixa diferente) não é recriada.
#
# Nenhuma despesa fictícia é criada. Dado financeiro é do usuário: as seeds
# entregam só o vocabulário inicial de categorias, nada além.

if User.none?
  puts "Nenhum usuário cadastrado — nada a semear (categorias são por usuário)."
else
  User.find_each do |user|
    Category.seed_defaults_for!(user)
    puts "Categorias padrão garantidas para #{user.email}"
  end

  # Perfil de bootstrap: num banco recém-criado ninguém tem perfil, e sem um
  # admin o app fica inacessível — o gate exige um perfil que não existe.
  #
  # Só quando NÃO HÁ NENHUM admin, e só no usuário mais antigo. Num app que já
  # tem admins isto não concede nada a ninguém.
  if User.with_role(Profiles::ADMIN).none?
    primeiro = User.order(:id).first
    primeiro.add_role(Profiles::ADMIN)
    puts "Perfil #{Profiles::ADMIN} concedido a #{primeiro.email} (bootstrap)."
  end
end
