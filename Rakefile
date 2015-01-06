begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'socket'
require 'active_support/core_ext/string/strip'
require 'rake/testtask'

EXPANDED_CWD = File.expand_path(File.dirname(__FILE__))

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

# Just ignore this if rake is not runned from the current directory, as is the
# case with docker's container. BUNDLE_GEMFILE won't do for our case, since the
# Gemfile references gemspec.
Bundler::GemHelper.install_tasks if defined? Bundler::GemHelper

task default: :test
