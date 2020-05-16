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

    on "delete_player", param("player_for_delete") do |player|
      conn.exec_params("delete from players where id =($1)",
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
    on "players" do
      players = []
      conn.exec("select name, id from players") do |result|
        result.each do |row|
          players << row
        end
      end

      render "players", players: players
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
    on root do
      res.redirect("/games")
    end
  end
end
