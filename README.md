# betunfair

# Comands for generating the database.
- Create database: mix ecto.create
- Command schema of users: mix phx.gen.schema Betunfair.User users id_users:string:unique balance:integer name:string
- Command schema of market: mix phx.gen.schema Betunfair.Market markets name:string description:string status:string
- Command schema of bet: mix phx.gen.schema Betunfair.Bet bets odds:integer type:string original_stake:integer remaining_stake:integer user_id:references:users market_id:references:markets
- Command schema of market: mix phx.gen.schema Betunfair.Matched matched id_bet_backed:references:bets id_bet_layed:references:bets
- Insert schema information into the database: mix ecto.migrate



