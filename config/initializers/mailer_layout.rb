# O ActionMailer NÃO usa app/views/layouts/mailer.html.erb por convenção: é
# preciso declarar `layout` explicitamente (ver actionmailer/lib/action_mailer/base.rb,
# onde `layout 'mailer'` aparece apenas como exemplo comentado).
#
# Sem isto, o arquivo app/views/layouts/mailer.html.erb existia mas nunca era
# aplicado — os e-mails saíam sem cabeçalho, sem CTA e sem rodapé.
#
# Declaramos no ActionMailer::Base para valer para todos os mailers (é o que o
# arquivo de layout pressupõe). Devise::Mailer herda de ActionMailer::Base.
ActiveSupport.on_load(:action_mailer) do
  layout "mailer"
end
