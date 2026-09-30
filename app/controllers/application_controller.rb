class ApplicationController < ActionController::Base
  # Pundit 2.5 não inclui sozinho: sem isto, `policy` e `authorize` não existem.
  # (`include Pundit` está deprecado e emite warning.)
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!

  # Autorização do app inteiro: só quem tem perfil entra.
  #
  # Depois de `authenticate_user!` DE PROPÓSITO: quem não tem sessão deve ver o
  # login, não a tela de bloqueio.
  #
  # `unless: :devise_controller?` é obrigatório. `DeviseController` herda deste
  # controller e NÃO faz skip de filtros — o `authenticate_user!` do Devise só é
  # no-op em controller do Devise porque o método gerado é
  # `warden.authenticate!(opts) if !devise_controller? || opts.delete(:force)`;
  # um filtro NOSSO não tem esse no-op. A guarda cobre também o cancelamento de
  # conta e a edição de cadastro, que precisam seguir acessíveis a quem não tem
  # perfil.
  #
  # Rotas que não passam por aqui e por isso não precisam de exceção:
  # - `/up` (Rails::HealthController) não herda de ApplicationController;
  # - assets são servidos por middleware, não por controller.
  #
  # Toda rota pública nova (webhook, API) vai precisar de
  # `skip_before_action :require_profile`.
  before_action :require_profile, unless: :devise_controller?

  # Rede para uma autorização por ação que venha a falhar. O gate NÃO passa por
  # aqui — ver `require_profile`.
  rescue_from Pundit::NotAuthorizedError, with: :profile_required

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Como a lista de despesas está sendo olhada: ordem manual, por custo ou por
  # categoria.
  #
  # Vive na sessão porque os Turbo Streams redesenham a lista sem passar pelo
  # HomeController — sem isto, criar uma despesa devolveria a lista para a
  # ordem manual no meio de uma ordenação por custo.
  helper_method :ledger_sort

  def ledger_sort
    session[:ledger_sort].presence || "manual"
  end

  protected

  # Pergunta pelo predicado, e não com `authorize`: o `authorize` do Pundit
  # marca a request como autorizada, e este filtro roda em TODAS elas — o que
  # tornaria `verify_authorized` permanentemente satisfeito se um dia ele for
  # ligado.
  def require_profile
    return if policy(current_user).access_app?

    profile_required
  end

  # Um só lugar decide o que "sem permissão" significa: vale para o gate e para
  # qualquer `authorize` de ação que falhe depois.
  #
  # REDIRECT, e não um 403 renderizado. Numa requisição `turbo_stream` — que
  # este app faz, ao criar despesa e ao reordenar — o Turbo não tem
  # `responseHTML` e não desenha nada: o botão fica morto, sem erro visível.
  # Renderizar 403 exigiria forçar formato e viraria UnknownFormat nas
  # requisições não-HTML. O redirect funciona igual em HTML puro, Turbo Drive e
  # turbo_stream.
  #
  # 303 e não 302: o gate intercepta POST e DELETE também, e 303 é a semântica
  # correta de "o resultado está em outro lugar, busque-o com GET".
  def profile_required
    redirect_to lock_path, status: :see_other
  end

  # Com authentication_keys = [:username], o Devise deixa de permitir :email
  # por padrão, então ele precisa ser liberado explicitamente aqui.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :email, :full_name, :username ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :email, :full_name, :username ])
  end
end
