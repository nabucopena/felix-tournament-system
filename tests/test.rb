require_relative "../models.rb"
$conn = PG.connect(ENV.fetch("DATABASE_URL"))
def db_test(name, &block)
  $conn.exec("begin")
  test(name, &block)
  $conn.exec("rollback")
end

db_test "create players" do
  Games.create_player("fulano")
  result = $conn.exec("select count(*)
  	from players
  	where name = 'fulano'").first.fetch("count")
  assert_equal result.to_i, 1
end

db_test "delete players" do
  $conn.exec("insert into players(id, name) values(15, 'fulano')")
  Games.delete_player(15)
  result = $conn.exec("select count(*)
  	from players
  	where name = 'fulano'").first.fetch("count")
  assert_equal result.to_i, 0
end

db_test "list players" do
  $conn.exec("insert into players(id, name)
    values
    (15, 'fulano'),
    (16, 'mengano')")
  result = Games.list_players
  assert_equal result, [
    {"id" => "15", "name" => "fulano"},
    {"id" => "16", "name" => "mengano"}
  ]
end

db_test "list player games" do
  $conn.exec("insert into players(id, name)
    values
    (15, 'fulano'),
    (16, 'mengano')")
  $conn.exec("insert into games(id_player_1, id_player_2, score_1, score_2)
    values(15, 16, 21, 15)")
  result = Games.list_player_games(15)
  assert_equal result, [
    {"score" => "21", "opponent_score" => "15", "opponent" => "mengano"}
  ]
end

db_test "get player name by id" do
  $conn.exec("insert into players(id, name) values(15, 'fulano')")
  result = Games.get_player_name_by_id(15)
  assert_equal result, {"name" => "fulano"}
end

db_test "list games" do
  $conn.exec("insert into players(id, name)
    values
    (15, 'fulano'),
    (16, 'mengano'),
    (17, 'zutano')")
  $conn.exec("insert into games(id_player_1, id_player_2, score_1, score_2)
    values(15, 16, 21, 15)")
  result = Games.list_games
  assert_equal result, [
    {"p1_name" => "fulano",
      "p2_name" => "mengano",
      "p1_id" => "15",
      "p2_id" => "16",
      "score_1" => "21",
      "score_2" => "15"}
  ]
end

db_test "fixture" do
  $conn.exec("insert into players(id, name)
    values
    (15, 'fulano'),
    (16, 'mengano'),
    (17, 'zutano')")
  $conn.exec("insert into games(id_player_1, id_player_2, score_1, score_2)
    values(15, 16, 21, 15)")
  result = Games.fixture
  assert_equal result, [
    {"p1_name" => "fulano",
      "p2_name" => "mengano",
      "p1_id" => "15",
      "p2_id" => "16",
      "score_1" => "21",
      "score_2" => "15"},
    {"p1_name" => "fulano",
      "p2_name" => "zutano",
      "p1_id" => "15",
      "p2_id" => "17",
      "score_1" => nil,
      "score_2" => nil},
    {"p1_name" => "mengano",
      "p2_name" => "zutano",
      "p1_id" => "16",
      "p2_id" => "17",
      "score_1" => nil,
      "score_2" => nil}
  ]
end

db_test "set scores" do
  $conn.exec("insert into players(id, name)
    values
    (15, 'fulano'),
    (16, 'mengano')")
  Games.set_scores(id1: 15, id2: 16, score1: 21, score2: 15)
  result = $conn.exec("select * from games").to_a
  assert_equal result, [
    {"id_player_1" => "15",
      "id_player_2" => "16",
      "score_1" => "21",
      "score_2" => "15"}
  ]
end

db_test "list positions" do
  $conn.exec("insert into players(id, name)
    values
    (15, 'fulano'),
    (16, 'mengano'),
    (17, 'zutano')")
  $conn.exec("insert into games(id_player_1, id_player_2, score_1, score_2)
    values(15, 16, 21, 15)")
  result = Games.list_positions
  assert_equal result, [
    {"name" => "fulano",
      "played" => "1",
      "won" => "1"},
    {"name" => "zutano",
      "played" => "0",
      "won" => "0"},
    {"name" => "mengano",
      "played" => "1",
      "won" => "0"}
  ]
end