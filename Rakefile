require "bundler"
Bundler.setup
require 'dotenv/tasks'

task :test do
  $LOAD_PATH.unshift('test')
  Dir.glob("./test/*_test.rb") { |f| require f }
end

task default: :test

desc "Open an pry session with Gasoline loaded"
task :console do
  require 'pry'
  require './junior'
  ARGV.clear
  Pry.start Junior
end
