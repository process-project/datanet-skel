source 'https://rubygems.org'

# Specify your gem's dependencies in datanet-skel.gemspec
gemspec

gem 'grid-proxy', git: 'git@dev.cyfronet.pl:commons/grid-proxy.git'
gem 'ruby-gridftp', git: 'git@dev.cyfronet.pl:commons/ruby-gridftp.git'

group :development, :test do
  gem 'rake'

  gem 'shotgun'
  gem 'pry'

  gem 'guard'
  gem 'guard-rspec', '~>3.0.2'

  gem 'rspec'
  gem 'rspec-mocks'
  gem 'rack-test'

  gem 'libnotify'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
end
