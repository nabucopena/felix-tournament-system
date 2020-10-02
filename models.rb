require "pg"
require "bcrypt"
require "requests"
require "fastimage"

class Games
  def self.resetdb
    $conn.exec(
      "delete from games"
    )
    $conn.exec(
      "delete from players"
    )
  end

  def self.create_player(new_player)
    $conn.exec_params(
      "insert into players (name) values ($1)",
      [new_player]
    )
  end

  def self.delete_player(player)
    $conn.exec_params(
      "delete from players where id =($1)",
      [player]
    )
  end

  def self.list_players
    $conn.exec("select name, id from players").to_a
  end

  def self.list_player_games(player_id)
  	$conn.exec_params(
      "select my_score as score,
      opponent_score,
      name as opponent
      from my_games
      join players
      on opponent_id=id
      where my_id=$1",
      [player_id]
    ).to_a
  end

  def self.get_player_name_by_id(player_id)
  	$conn.exec_params(
      "select name from players where id=$1", [player_id]
    ).first
  end

  def self.list_games
    sql = "select p1.name as p1_name,
      p2.name as p2_name,
      p1.id as p1_id,
      p2.id as p2_id,
      games.score_1,
      games.score_2
      from players p1
      join players p2 on p1.id < p2.id
      join games on p1.id = games.id_player_1 and p2.id = games.id_player_2"
    $conn.exec(sql).to_a
  end

  def self.fixture
    sql = "select p1.name as p1_name,
      p2.name as p2_name,
      p1.id as p1_id,
      p2.id as p2_id,
      games.score_1,
      games.score_2
      from players p1
      join players p2 on p1.id < p2.id
      left join games on p1.id = games.id_player_1 and p2.id = games.id_player_2"
    $conn.exec(sql).to_a
  end

  def self.set_scores(id1:, id2:, score1:, score2:)
    $conn.exec_params("insert into games (
    	id_player_1,
    	id_player_2,
    	score_1,
    	score_2
    	)
    	values ($1, $2, $3, $4)
    	on conflict(id_player_1, id_player_2)
    	do
    	update set score_1 = $3, score_2 = $4",
    	[id1, id2, score1, score2])
  end

  def self.list_positions
  	sql = <<~SQL
      select name,
      count(*) filter(where my_id is not null) as played,
      count(*) filter(where id=my_id and my_score>opponent_score) as won
      from players
      left join my_games on my_id=id
      group by id;
      SQL
    $conn.exec(sql).to_a
  end
end

class Accounts

  def self.change_avatar(url:, id:)
    begin
      response = Requests.request("GET", url)
      type = FastImage.type(url).to_s
      if type == "png"
        File.write("public/#{id}.png", response.body)
      else
        error = "invalid image"
      end
    rescue Errno::ECONNREFUSED => e
      error = "No image found"
    end
    {error: error}
  end

  def self.check_login(user, password)
    result = $conn.exec_params("select
      id, username, password
      from users
      where username=$1",
      [user]).first
    id = result.fetch("id")
    if result
      if BCrypt::Password.new(result.fetch("password"))==password
        {user: {name: user, id: id}}
      else
        {error: "Invalid password"}
      end
    else
      {error: "Invalid username"}
    end
  end


  def self.create_account(user, password)
    used_name = $conn.exec_params("select count(*)
      from users
      where username=$1",
      [user]).first.fetch("count").to_i
    if used_name>0
      {error: "This username is already registered"}
    else
      encrypted = BCrypt::Password.create(password)
      id = $conn.exec_params("insert into users
        (username, password) values ($1, $2) returning id",
        [user, encrypted]).first.fetch("id")
      response = Requests.request("GET",
        "https://api.adorable.io/avatars/144/#{id}.png")
      File.write("public/#{id}.png", response.body)
      {user: {name: user, id: id}}
    end
  end
end
