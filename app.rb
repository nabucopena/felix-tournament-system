require "cuba"
require "pg"
conn = if ENV["DATABASE_URL"]
         PG.connect(ENV["DATABASE_URL"])
       else
         PG.connect(dbname: "felix")
       end

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

      res.write <<~HTML
        <html>
          <body>
            <h1> Players </h1>
            #{players.map do |x| "<p>#{x}</p>"end.join}
            <form method="post" action="/create_new_player"> 
               <input type="text" name="player1">
               <input type="submit">
             </form>
          </body>
        </html>
      HTML
    end

    on "games" do
      trs = []
      sql = "select p1.name as p1_name, p2.name as p2_name, p1.id as p1_id, p2.id as p2_id from players p1 join players p2 on p1.id < p2.id"
      conn.exec(sql) do |result| 
        result.each.with_index do |row, i|
          trs << <<~HTML
            <tr>
              <td>#{row.fetch('p1_name')}</td>
              <td>#{row.fetch('p2_name')}</td>
              <td>
                <input type="hidden" name="score[#{i}][p1_id]" value="#{row.fetch("p1_id")}">
                <input type="hidden" name="score[#{i}][p2_id]" value="#{row.fetch("p2_id")}">
                <input type="number" name="score[#{i}][score1]"></td>
              <td><input type="number" name="score[#{i}][score2]"></td>
            </tr>
          HTML
        end
      end

      res.write <<~HTML
        <html>
          <body>
            <h1>Games</h1>
            <form method="post" action="/scores">
              <table>
                <tr>
                  <td>Player 1</td>
                  <td>Player 2</td>
                  <td>Scores 1</td>
                  <td>Scores 2</td>
                </tr>
                #{trs.join}
              </table>
              <input type="submit">
            </form>
          </body>
        </html>
      HTML
    end
  end
end
