require "cuba"
require "cuba/mote"
require "pg"
require "bcrypt"
require "./db_connection"
DBConnection.connect
module Helpers
  def current_user
    session[:user]
  end
  def conn
    $conn
  end
end

Cuba.use Rack::Session::Cookie, :secret => ENV.fetch("COOKIE_SECRET")
Cuba.plugin Cuba::Mote
Cuba.plugin Helpers
Cuba.define do

  on root do
    if current_user
      render "homepage"
    else
      render("homepage", {}, "unlogged_layout")
    end
  end

  on "login" do
    on get do
      render("login", {}, "unlogged_layout")
    end
    on post do
      on param("username"), param("password") do |user, password|
        result = conn.exec_params("select
          username, password
          from users
          where username=$1",
        [user]).first
        on result do
          on BCrypt::Password.new(result.fetch("password"))==password do
            session[:user]=user
            res.redirect("/games")
          end
          session[:error] = "Invalid password"
          res.redirect("/login")
        end
        session[:error] = "Invalid username"
        res.redirect("/login")
      end
      res.redirect("/login")
    end
  end

  on post, "logout" do
    session.clear
    res.redirect("/login")
  end

  on post, "register_user" do
    on param("user"), param("password") do |user, password|
      used_name = conn.exec_params("select count(*) from users where username=$1", [user])
      on used_name[0].fetch("count").to_i>0 do
        session[:error] = "This username is already registered"
        res.redirect("/register")
      end
      conn.exec_params("insert into users
        (username, password) values ($1, $2)",
        [user, BCrypt::Password.create(password)])
      session[:user]=user
      res.redirect("/games")
    end
    session[:error] = "All parameters required"
    res.redirect("/register")      
  end

  on get, "register" do
      render("register", {}, "unlogged_layout")
  end
  
  on !!current_user do
    on post do
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
      on "positions" do
        sql = <<~SQL
          select name,
          count(*) filter(where my_id is not null) as played,
          count(*) filter(where id=my_id and my_score>opponent_score) as won
          from players
          left join my_games on my_id=id
          group by id;
          SQL
        players = conn.exec(sql)
        render("positions", {players: players})
      end

      on "players" do
        on root do
          players = []
          conn.exec("select name, id from players") do |result|
            result.each do |row|
              players << row
            end
          end
          render "players", players: players
        end
        on ":id" do |id|
          player = conn.exec_params(
            "select name from players where id=$1", [id]
            ).first
          on player do
            games = conn.exec_params(
              "select my_score as score,
              opponent_score,
              name as opponent
              from my_games
              join players
              on opponent_id=id
              where my_id=$1",
              [id]
              )
            render "player", {
              player: player,
              games:games
              }
          end
        end
      end

      on "games" do
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
    end
  end

  on true do
    res.redirect("login")
  end
end
