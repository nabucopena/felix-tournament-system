require "cuba"
require "cuba/mote"
require "pg"
conn = if ENV["DATABASE_URL"]
         PG.connect(ENV["DATABASE_URL"])
       else
         PG.connect(dbname: "felix")
       end

Cuba.use Rack::Session::Cookie, :secret => ENV.fetch("COOKIE_SECRET")
Cuba.plugin Cuba::Mote
Cuba.define do
  on post do

    on "send_message" do
      on param("message"), param("user") do |message, user|
        conn.exec_params("insert into messages(message, sender, receiver) values ($1, $2, $3)", [message, session[:user], user])
      res.redirect("/chat")
      end
      res.redirect("/chat")
    end

    on "chat", param("sender") do |sender|
      messages = []
      receiver = session[:user]
      conn.exec_params("select message, sender from messages where (sender=$1 and receiver=$2) or(sender=$2 and receiver=$1)", [sender, receiver]) do |result|
        result.each do |message|
          message["rec"]=""
          if message.fetch("sender")==receiver
            message["rec"]="color:green"
          end
          messages << message
        end
      end
      render("show_messages", messages: messages, sender: sender)  
    end

    on "register_user" do
      on param("user"), param("password") do |user, password|
        used_name = conn.exec_params("select count(*) from users where username=$1", [user])
        on used_name[0].fetch("count").to_i>0 do
          session[:error] = "This username is already registered"
          res.redirect("/register")
        end
        conn.exec_params("insert into users (username, password) values ($1, $2)", [user, password])
        session[:log]="logged"
        session[:user]=user
        res.redirect("/games")
      end
      session[:error] = "All parameters required"
      res.redirect("/register")      
    end

    on "log", param("username"), param("password") do |user, password|
      possible = []
      conn.exec_params("select
        username, password
        from users
        where username=$1",
        [user]) do |result|
        result.each do |row|
          on row.fetch("password")==password do
            session[:log]="logged"
            session[:user]=user
            res.redirect("/games")
          end
          session[:error] = "Invalid password"
        end
        session[:error] = "Invalid username"
      end
      res.redirect("/login")
    end

    on "delete_player", param("player_for_delete") do |player|
      conn.exec_params("delete from players where id =($1)",
        [player])
      conn.exec_params("delete from games where id_player_1 =($1) or id_player_2=($1)",
        [player])
      res.redirect("/players")
    end


    on "scores" do
      on param("id1"), param("id2"), param("score1"), param("score2") do |id1, id2, score1, score2|
        conn.exec_params("insert into games (id_player_1, id_player_2, score_1, score_2) values ($1, $2, $3, $4) on conflict(id_player_1, id_player_2) do update set score_1 = $3, score_2 = $4", [id1, id2, score1, score2])
        res.redirect("/games")
      end
      session[:error] = "Scores are required"
      res.redirect("/games")
    end

    on "create_new_player", param("player1") do |new_player|
      conn.exec_params("insert into players (name) values ($1)", [new_player])
      res.redirect("/players")
    end
  end

  on get do

    on "chat" do
      on session[:log]!= "logged" do
        res.redirect("/login")
      end
      render "chat"
    end
    
    on "register" do
      render "register"
    end

    on "logout" do
      session[:log]="out"
      session[:user]=nil
      res.redirect("/games")
    end

    on "login" do
      render "login"
    end

    on "players" do
      on session[:log]!= "logged" do
        res.redirect("/login")
      end
      players = []
      conn.exec("select name, id from players") do |result|
        result.each do |row|
          players << row
        end
      end

      render "players", players: players
    end

    on "games" do
      on session[:log]!= "logged" do
        res.redirect("/login")
      end
      games = []
      sql = "select p1.name as p1_name,
        p2.name as p2_name,
        p1.id as p1_id,
        p2.id as p2_id,
        games.score_1,
        games.score_2
        from players p1
        join players p2 on p1.id < p2.id
        left join games on p1.id = games.id_player_1 and p2.id = games.id_player_2"
      conn.exec(sql) do |result| 
        result.each do |row|
          games << row
        end
      end
      render("games", games: games)
    end

    on "show_results" do
      on session[:log]!= "logged" do
        res.redirect("/login")
      end
      results = []
      sql = "select p1.name as p1_name,
        p2.name as p2_name,
        p1.id as p1_id,
        p2.id as p2_id,
        games.score_1,
        games.score_2
        from players p1
        join players p2 on p1.id < p2.id
        join games on p1.id = games.id_player_1 and p2.id = games.id_player_2"
      conn.exec(sql) do |result| 
        result.each do |row|
          results << row
        end
      end
      render("show_results", results: results)
    end
    on root do
      render "homepage"
    end
  end
end
