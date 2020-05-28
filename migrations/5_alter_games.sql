alter table games
add constraint not_same_player
check (id_player_1!=id_player_2);
