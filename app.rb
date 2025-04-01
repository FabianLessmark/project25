require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

DB = SQLite3::Database.new "db/project2025.db"
DB.results_as_hash = true  

def generate_games
  team_ids = DB.execute("SELECT id FROM teams").flatten.shuffle

  if team_ids.size < 16
    puts "Not enough teams to generate 8 games!" 
  else
    DB.execute("DELETE FROM games") # Rensar tidigare matcher

    8.times do
      break if team_ids.size < 2
      team1, team2 = team_ids.pop(2)
      puts team1
      puts team2
      DB.execute("INSERT INTO games (team_id1, team_id2) VALUES (?, ?)", [team1["id"], team2["id"]])
    end
  end
end

get('/') do
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

post('/shuffle_teams') do
  generate_games
  redirect '/games'
end

get('/bets/:game_id') do
  @game = DB.execute("SELECT games.id, teams1.name AS team1_name, teams2.name AS team2_name FROM games JOIN teams AS teams1 ON games.team_id1 = teams1.id JOIN teams AS teams2 ON games.team_id2 = teams2.id WHERE games.id = ?", params[:game_id]).first
  slim(:bets)
end