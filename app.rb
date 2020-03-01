require "cuba"
require "cuba/mote"
require "pg"
conn = if ENV["DATABASE_URL"]
         PG.connect(ENV["DATABASE_URL"])
       else
         PG.connect(dbname: "felix")
       end

Cuba.plugin Cuba::Mote

Cuba.define do
  on post do
    on "scores" do
      res.write "To be done"
      # score = req.params.fetch("score")
    end

    on "create_new_player", param("player1") do |new_player|
       conn.exec_params("insert into players (name) values ($1)", [new_player])
       res.redirect("/players")
    end
  end

  on get do
    on "players" do
      players = []
      conn.exec("select name from players") do |result|
        result.each do |row|
          player = row.fetch("name")
          players << player
        end
      end

      render "players", players: players
    end

    on "games" do
      games = []
      sql = "select p1.name as p1_name, p2.name as p2_name, p1.id as p1_id, p2.id as p2_id from players p1 join players p2 on p1.id < p2.id"
      conn.exec(sql) do |result| 
        result.each do |row|
          games << row
        end
      end

      render("games", games: games)
    end

    on root do
      res.redirect("/games")
    end

  end
end
