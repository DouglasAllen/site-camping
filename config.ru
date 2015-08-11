$:.unshift(File.expand_path('../vendor/', __FILE__))
require 'sqlite3'

require './app/app1'
require './app/blog'

map '/' do
  run Watch
end

map '/blog' do
  ActiveRecord::Base.establish_connection(
      :adapter  => 'sqlite3',
      :database => 'db/development.sqlite3',
      :encoding => 'utf8'
      )
  
  run Blog
end
