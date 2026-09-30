namespace :roles do
  desc "Concede um perfil a um usuário. Ex.: rails roles:grant[renato,admin]"
  task :grant, [ :username, :profile ] => :environment do |_t, args|
    username, profile = args[:username], args[:profile]

    abort "uso: rails roles:grant[username,perfil] — perfis: #{Profiles::NAMES.join(', ')}" if username.blank? || profile.blank?

    # Valida contra o vocabulário ANTES de tocar no banco: o erro do rolify para
    # perfil desconhecido (RecordInvalid vindo de dentro da associação) não diz
    # ao operador o que fazer.
    unless Profiles.known?(profile)
      abort "perfil desconhecido: #{profile.inspect}. Conhecidos: #{Profiles::NAMES.join(', ')}"
    end

    user = User.find_by(username: username)
    abort "usuário não encontrado: #{username}" if user.nil?

    if user.has_role?(profile)
      puts "#{username} já tem o perfil #{profile}."
    else
      user.add_role(profile)
      puts "#{username} recebeu o perfil #{profile}."
    end
  end

  desc "Tira um perfil de um usuário. Ex.: rails roles:revoke[renato,admin]"
  task :revoke, [ :username, :profile ] => :environment do |_t, args|
    username, profile = args[:username], args[:profile]

    abort "uso: rails roles:revoke[username,perfil]" if username.blank? || profile.blank?

    user = User.find_by(username: username)
    abort "usuário não encontrado: #{username}" if user.nil?

    if user.has_role?(profile)
      user.remove_role(profile)
      puts "#{username} perdeu o perfil #{profile}."
    else
      puts "#{username} não tem o perfil #{profile}."
    end
  end

  desc "Lista quem tem cada perfil conhecido."
  task who: :environment do
    Profiles::ALL.each do |profile|
      nomes = User.with_role(profile).order(:username).pluck(:username)

      # Uma lista vazia aqui é o cenário de lockout: o gate exige este perfil e
      # não há ninguém que o tenha.
      aviso = nomes.empty? ? "  <-- ninguém. O app está inacessível." : ""
      puts "#{profile}: #{nomes.any? ? nomes.join(', ') : '(ninguém)'}#{aviso}"
    end
  end
end
