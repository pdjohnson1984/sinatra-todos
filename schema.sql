create table todo (id serial primary key,
name varchar(255),
completed boolean default false,
list_id integer references list(id));

create table list(id serial primary key,
name varchar(255) unique not null);
