$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'shoppe/stripe/version'

Gem::Specification.new do |s|
  s.name        = 'shoppe-stripe'
  s.version     = Shoppe::Stripe::VERSION
  s.authors     = ['Adam Cooke']
  s.email       = ['adam@niftyware.io']
  s.homepage    = 'http://tryshoppe.com'
  s.summary     = 'A Stripe module for Shoppe.'
  s.description = 'A Stripe module to assist with the integration of Stripe.'

  s.files = Dir['{lib,vendor/assets}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.post_install_message = 'Since v1.3.0, the params for exp_month & exp_year have changed - https://git.io/vgl3c'

  s.add_dependency 'shoppe', '> 0.0.9', '< 2'
  s.add_dependency 'stripe', '~> 1.8.7'
  s.add_dependency 'coffee-rails', '~> 4'
end
