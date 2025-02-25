require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

get('/')  do
  slim(:start)
end 

get('/games') do
  slim(:games)
end

get('/account') do
  slim(:account)
end