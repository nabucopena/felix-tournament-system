create view my_games as (
    select score_1 as my_score,
    score_2 as opponent_score,
    id_player_1 as my_id,
    id_player_2 as opponent_id
    from games
    union
    select score_2,
    score_1,
    id_player_2,
    id_player_1
    from games
    );