# betunfair

# Comands for generating the database.
- Create database: mix ecto.create
- Command schema of users: mix phx.gen.schema Betunfair.User users id_users:string:unique balance:integer name:string
- Command schema of market: mix phx.gen.schema Betunfair.Market markets name:string description:string status:string
- Command schema of bet: mix phx.gen.schema Betunfair.Bet bets odds:integer type:string original_stake:integer remaining_stake:integer user_id:references:users market_id:references:markets
- Command schema of market: mix phx.gen.schema Betunfair.Matched matched id_bet_backed:references:bets id_bet_layed:references:bets
- Insert schema information into the database: mix ecto.migrate

## create and initialize db

requirements: psql and pg_ctl installed (postgres client and server applications for cli)

create a postgresql database server:

```
export PGDATA=/path/to/your/db
source ~/.bashrc
pg_ctl init
#*change unix_socket_directory on /path/to/your/db/postgresql.conf*
pg_ctl start
```
change the unix_socket_directory to /tmp in order to run a local instance
-> https://stackoverflow.com/a/72294531

run the psql client:
```
psql -h /tmp/ postgres #accessing the database
```

inside the postgres database:
```
CREATE ROLE postgres LOGIN;
ALTER USER postgres CREATEDB;
```

then on the mix project
```
$ iex -S mix
iex> mix ecto.create
#no need to create the schemas (they are already created)
iex> mix ecto.migrate
```

### run a psql client instance to see databases and created tables:

inside psql:
```
\l #see postgre databases
\c betunfair_dev #connect to our db
\dt #display tables
\d bets #see schemas of the Bets table eg.
\du #display users and permissions
#display table info with standard sql queries (SELECT...)
```
-> more at: https://tomcam.github.io/postgres/
