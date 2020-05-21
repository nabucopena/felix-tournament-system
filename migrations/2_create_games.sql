create table games(
	id_player_1 int not null references players(id),
	id_player_2 int not null references players(id),
	score_1 int not null,
	score_2 int not null,
	primary key(id_player_1, id_player_2)
)