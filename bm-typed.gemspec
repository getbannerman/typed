# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'lib/typed/version')

Gem::Specification.new do |gem|
  gem.name = 'bm-typed'
  gem.version       = Typed::VERSION
  gem.licenses      = ['MIT']
  gem.authors       = ['Frederic Terrazzoni']
  gem.email         = ['frederic.terrazzoni@gmail.com']
  gem.description   = 'A dry-types/dry-struct alternative making '\
                      'the difference between undefined and nil'
  gem.summary       = gem.description
  gem.homepage      = 'https://github.com/getbannerman/typed'

  gem.files         = `git ls-files lib`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = []
  gem.test_files    = []
  gem.require_paths = ['lib']

  gem.add_development_dependency 'coveralls', '~> 0.8'
  gem.add_development_dependency 'pry', '~> 0'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'rubocop', '0.59.2'

  gem.add_dependency 'activesupport', '~> 6.0'
  gem.add_dependency 'dry-logic', '~> 0.4.2'
end
