require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

DB = SQLite3::Database.new "db/project2025.db"
DB.results_as_hash = true  

team_ids = DB.execute("SELECT id FROM teams").flatten.shuffle

(1..8).each do
  team1, team2 = team_ids.pop(2)  # Pick two random teams
  db.execute("INSERT INTO games (team_id1, team_id2) VALUES (?,?)", [team1, team2])
end

get('/')  do
  slim(:start)
end 

get('/teams') do
  @data = DB.execute("SELECT * FROM teams")   
  slim(:teams)
end

get('/games') do
  @games = DB.execute("SELECT * FROM games")
  slim(:games)
end

get('/account') do
  slim(:account)
end