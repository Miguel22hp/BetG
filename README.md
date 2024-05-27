# BetUnfair

Betting Exchange Platform written in Elixir for the Programming Scalable Systems subject @ Polythetnic University of Madrid

This project includes a GUI made with the Phoenix framework to interact with the internal API.

![web GUI](pictures/web.jpg)

## Comands for generating the database & installing dependencies

> [!IMPORTANT]
> some of the steps (related to the psql setup) aren't required for certain linux distributions

requirements:
- elixir (iex and mix)
- psql
- pg_ctl

compile the project
```
iex -S mix
```

Install dependencies (inside iex)
```
mix deps.get
```

create a postgresql database server (outside iex)

```
export PGDATA=/path/to/the/db
source ~/.bashrc
pg_ctl init
#in any text editor: *change unix_socket_directory on /path/to/the/db/postgresql.conf*
pg_ctl start
```
-> change the unix_socket_directory to /tmp in order to run a local instance (https://stackoverflow.com/a/72294531)

run the psql client
```
psql -h /tmp/ postgres #accessing the database
```

inside the postgres database:
```
CREATE ROLE postgres LOGIN;
ALTER USER postgres CREATEDB;
```

inside psql:
```
\l #see postgre databases
\c betunfair_dev #connect to our db
\dt #display tables
\d bets #see schemas of the Bets table eg.
\du #display users and permissions
#display table info with standard sql queries (SELECT...)
```
-> more at https://tomcam.github.io/postgres/

create Ecto database (inside iex)
```
mix ecto.create
```

generate Ecto Schemas of module: user, bet, market and bet (no need to do it, since the project already has it generated)
```
mix phx.gen.schema Betunfair.User users id_users:string:unique balance:integer name:string
mix phx.gen.schema Betunfair.Market markets name:string description:string status:string
mix phx.gen.schema Betunfair.Bet bets odds:integer type:string original_stake:integer remaining_stake:integer user_id:references:users 
mix phx.gen.schema Betunfair.Matched matched id_bet_backed:references:bets id_bet_layed:references:bets
```

insert schema information into the database
```
mix ecto.migrate
```

execute the Phoenix app
```
mix phx.server
```