create table messages (
	id serial primary key,
	message text,
	sender text references users(username),
	receiver text references users(username)
	);