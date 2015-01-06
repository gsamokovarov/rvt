source 'https://rubygems.org'

gemspec

group :development do
  gem 'puma'

  # Only require this one explicitly.
  gem 'pry-rails', require: false

  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
  end

  platforms :ruby do
    gem 'thin'
    gem 'sqlite3'
  end
end

group :test do
  gem 'rake'
  gem 'mocha', require: false
  gem 'simplecov', require: false
end
