Rails.application.routes.draw do
  # Controllers em app/controllers/users/ apenas para aplicar o layout
  # dedicado das telas de autenticação (app/views/layouts/devise.html.erb).
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords",
    confirmations: "users/confirmations",
    unlocks: "users/unlocks",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # `except: :show` porque não existe tela de detalhe: uma categoria é o próprio
  # nome, e a listagem já mostra tudo. Editar é o "ver" desta entidade.
  resources :categories, except: :show

  # Criar, renomear e excluir rubrica. Excluir pede confirmação: leva as
  # despesas da rubrica junto, e isso não é óbvio pelo nome.
  resources :ledgers, only: %i[create update destroy] do
    # Regrava a ordem das despesas da rubrica. Recebe o estado final (a lista de
    # ids na ordem nova), não uma sequência de passos.
    patch :reorder, on: :member
  end

  # Itens de rubrica. Não é CRUD completo de propósito: o item nasce pela tela
  # inicial (a rubrica vem em `ledger_id`), e a única mutação depois disso é
  # marcar/desmarcar pago — a ação mais frequente do app.
  resources :ledger_items, only: %i[create update destroy] do
    # Desfazer a remoção. Recria o item a partir dos snapshots que vieram no
    # corpo do próprio snackbar — não há registro "pendente" no banco.
    post :restore, on: :collection

    # Editar o que a rubrica registra desta despesa (nome, valor, categoria).
    # Rota separada de `update` porque `update` é o toggle de pago — duas
    # intenções diferentes não devem dividir a mesma ação.
    patch :details, on: :member
  end

  # Tela de quem está logado mas não tem perfil. É para onde o gate do
  # ApplicationController manda — por isso é uma ROTA, e não um 403 renderizado
  # no lugar (ver o comentário de `profile_required`).
  #
  # Fora de qualquer bloco autenticado: quem não tem perfil precisa alcançá-la,
  # e é daqui que ele sai da conta.
  get "sem-permissao" => "lock#show", as: :lock

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
