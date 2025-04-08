require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'date'
enable :sessions


DB = SQLite3::Database.new "db/project2025.db"
DB.results_as_hash = true  

before do
  pass if ["/login", "/register"].include?(request.path_info)
  redirect('/login') unless session[:user_id]
end

get('/login') do
  slim(:login)
end

post('/login') do
  username = params[:username]
  password = params[:password]

  user = DB.execute("SELECT * FROM user WHERE username = ?", username).first

  if user && BCrypt::Password.new(user["password"]) == password
    session[:user_id] = user["id"]
    session[:access] = user["access"]
    session[:username] = user["username"]
    session[:saldo] = user["saldo"]  
    redirect '/'
  else
    @error = "Wrong username or password, if first time: create account"
    slim(:login)
  end
end

get('/logout') do
  session.clear
  redirect '/login'
end

get('/register') do
  slim(:register)
end

post('/register') do
  username = params[:username]
  password = params[:password]
  password_digest = BCrypt::Password.create(password)

  existing_user = DB.execute("SELECT * FROM user WHERE username = ?", username).first
  if existing_user
    @error = "Username already taken"
    slim(:register)
  else
    DB.execute("INSERT INTO user (username, password, access, saldo) VALUES (?, ?, ?, ?)", [username, password_digest, "user", 100])
    redirect '/login'
  end
end

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
  
  # Om spelet inte hittas, kan du omdirigera eller visa ett felmeddelande
  if @game.nil?
    redirect('/games')  # Eller annan passande sida
  else
    slim(:bets)
  end
end


post('/place_bet') do
  game_id = params[:game_id]
  bet_amount = params[:bet_amount].to_i
  bet_outcome = params[:bet]

  if bet_amount < 0 || bet_amount > 20
    @error = "Bet amount must be between 0 and 20."
    slim(:bets)
  else
    user_id = session[:user_id]
    user_balance = DB.execute("SELECT saldo FROM user WHERE id = ?", user_id).first["saldo"]

    if user_balance < bet_amount
      @error = "Exceeding your balance. You have #{user_balance} in your account."
      slim(:bets)  # Visa felmeddelande och återgå till bettsidan
    else
      # Dra av bettbeloppet från saldot
      DB.execute("UPDATE user SET saldo = saldo - ? WHERE id = ?", [bet_amount, user_id])

      # Logik för att registrera bettet
      DB.execute("INSERT INTO bets (user_id, game_id, bet_amount, bet_outcome) VALUES (?, ?, ?, ?)", 
                 [user_id, game_id, bet_amount, bet_outcome])

      # Uppdatera sessionen med det nya saldot
      new_balance = user_balance - bet_amount
      session[:saldo] = new_balance

      redirect '/games'  # Eller någon annan sida där du vill visa resultatet
    end
  end
end

get('/admin/users') do
  redirect('/') unless session[:access] == "admin"
  @users = DB.execute("SELECT * FROM user")
  slim(:admin_users)
end

post('/admin/users/delete/:id') do
  redirect('/') unless session[:access] == "admin"
  DB.execute("DELETE FROM user WHERE id = ?", params[:id])
  redirect('/admin/users')
end

post('/add_funds') do
  redirect('/login') unless session[:user_id]

  user_id = session[:user_id]
  DB.execute("UPDATE user SET saldo = saldo + 100 WHERE id = ?", user_id)

  saldo = DB.execute("SELECT saldo FROM user WHERE id = ?", user_id).first["saldo"]
  session[:saldo] = saldo

  redirect back
end

get('/logout') do
  session.clear
  redirect '/login'
end