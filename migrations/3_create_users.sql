create table users(
	id serial primary key,
	username text not null unique,
	password text not null
)