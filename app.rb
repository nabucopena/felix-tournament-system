require "cuba"
require "cuba/mote"
require "pg"
require "bcrypt"
require "./db_connection"
require "./models.rb"
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
        result = Accounts.check_login(user, password)
        session[:error] = result[:error]
        session[:user] = result[:user]
        res.redirect("/games")
      end
      session[:error] = "All parameters required"
      res.redirect("/login")
    end
  end

  on post, "logout" do
    session.clear
    res.redirect("/login")
  end

  on post, "register_user" do
    on param("user"), param("password") do |user, password|
      result = Accounts.create_account(user, password)
      session[:error] = result[:error]
      session[:user] = result[:user]
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
        Games.delete_player(player)
        res.redirect("/players")
      end


      on "scores" do
        on param("id1"), param("id2"), param("score1"), param("score2") do |id1, id2, score1, score2|
          Games.set_scores(id1: id1, id2: id2, score1: score1, score2: score2)
          res.redirect("/games")
        end
        session[:error] = "Scores are required"
        res.redirect("/games")
      end

      on "create_new_player", param("player1") do |new_player|
        Games.create_player(new_player)
        res.redirect("/players")
      end
    end

    on get do
      on "positions" do
        players = Games.list_positions
        render("positions", {players: players})
      end

      on "players" do
        on root do
          players = Games.list_players
          render "players", players: players
        end
        on ":id" do |id|
          player = Games.get_player_name_by_id(id)
          on player do
            games = Games.list_player_games(id)
            render "player", {
              player: player,
              games:games
              }
          end
        end
      end

      on "games" do
        games = Games.fixture
        render("games", games: games)
      end

      on "show_results" do
        results = Games.list_games
        render("show_results", results: results)
      end
    end
  end

  on true do
    res.redirect("login")
  end
end
