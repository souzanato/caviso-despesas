# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'rolify/version'

Gem::Specification.new do |s|
  s.name        = 'rolify'
  s.summary     = %q{Roles library with resource scoping}
  s.description = %q{Very simple Roles library without any authorization enforcement supporting scope on resource objects (instance or class). Supports ActiveRecord and Mongoid ORMs.}
  s.version     = Rolify::VERSION
  s.platform    = Gem::Platform::RUBY
  s.homepage    = 'https://github.com/RolifyCommunity/rolify'

  s.license     = 'MIT'

  s.authors     = [
    'Florent Monbillard',
    'Wellington Cordeiro'
  ]
  s.email       = [
    'f.monbillard@gmail.com',
    'wellington@wellingtoncordeiro.com'
  ]

  s.metadata = {
    'bug_tracker_uri'       => 'https://github.com/RolifyCommunity/rolify/issues',
    'changelog_uri'         => 'https://github.com/RolifyCommunity/rolify/blob/master/CHANGELOG.rdoc',
    'source_code_uri'       => 'https://github.com/RolifyCommunity/rolify',
    'rubygems_mfa_required' => 'true'
  }

  # `git ls-files` exigiria o binário git em tempo de EXECUÇÃO: o bundler
  # reavalia este gemspec a cada boot, e a imagem final de produção não tem git
  # (a de build tem). Sem ele o Gem::Specification.load devolvia nil e o app
  # não subia. A lista abaixo é fixa e não depende de repositório.
  s.files         = Dir.chdir(__dir__) { Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.rdoc", "UPGRADE.rdoc"] }
  s.executables   = []
  s.require_paths = ['lib']

  # ActiveRecord 8.x requires Ruby >= 3.2, which is also the oldest Ruby this
  # gem is tested against. See README for the full support matrix.
  s.required_ruby_version = '>= 3.2'

  s.add_development_dependency 'ammeter',       '~> 1.1' # Spec generator
  s.add_development_dependency 'appraisal',     '~> 2.5'
  s.add_development_dependency 'bundler',       '>= 2.4' # packaging feature
  s.add_development_dependency 'bundler-audit', '~> 0.9' # dependency security
  s.add_development_dependency 'rake',          '~> 13.0'
  s.add_development_dependency 'rspec-rails',   '>= 6.1'
end
