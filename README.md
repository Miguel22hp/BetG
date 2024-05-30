# BetUnfair

Betting Exchange Platform written in Elixir for the Programming Scalable Systems subject @ Polythetnic University of Madrid

This project includes a GUI made with the Phoenix framework to interact with the internal API.

![web GUI](pictures/web.jpg)

## Dependencies:

- psql (15.5) or higher versions.
- elixir (1.14) or higher versions.
- phoenix (1.7.12)

## PSQL setup
In case psql is not already set up, it is needed to follow this steps

### Step 1: Update Package List
```sh
sudo apt-get update
```
### Step 2: Step 2: Install PostgreSQL

```sh
sudo apt-get install postgresql
```
And verify the installation.
```sh
psql --version
```
### Step 3: Verify that psql user exist
```sh
psql -h hostname -U postgres -d dbname
```
If psql user does not exist, we need to create it:
```sh
CREATE USER postgres WITH PASSWORD 'postgres';
```

## Up and Running
execute in the root of the project the setup.sh file:

```sh
$ sh setup.sh
```

This script will:
- Check and install needed dependencies.
- Create the data base of the server in case it does not exist.
- Migrate all the tables needed for the project into the data base.
- Run all the tests for the application.
- Initialize the Application alongside the phoenix server for the web interface.

After executing this script, the phoenix server will be initialized with an empty database. To get some information in the database, you can write in the iex the following orders
```
# Create users 1 y 2 y check their operations
Betunfair.User.GestorUser.user_create("1", "U1") # Creates user 1
Supervisor.which_children(:user_supervisor) # Checks ":user_supervisor" children processes
Betunfair.User.OperationsUser.user_deposit(1, 200) # Deposits 200 in the user's 1 money 
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_withdraw(1, 100) # Withdraws 100 from the user's 1 money 
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.GestorUser.user_create("2", "U2") # Creates user 2
Betunfair.User.OperationsUser.user_deposit(2, 100) # Deposits 100 in the user's 2 money 
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information

# Create market 1 1
Betunfair.Market.GestorMarket.market_list()
Betunfair.Market.GestorMarket.market_list_active()
Betunfair.Market.GestorMarket.market_create("M1", "Mercado Ejemplo 1")
Betunfair.Market.GestorMarket.market_list()
Betunfair.Market.GestorMarket.market_list_active()
Supervisor.which_children(:market_supervisor)
Supervisor.which_children(:bet_supervisor)
Supervisor.which_children(:matched_supervisor)

# Crea apuestas del user 1 para el mercado 1
Betunfair.User.OperationsUser.user_get(1)
Betunfair.Bet.GestorMarketBet.bet_back(1, 1, 50, 1.5)
Betunfair.User.OperationsUser.user_get(1)
Betunfair.User.OperationsUser.user_get(2)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 1, 21, 1.5)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 1, 40, 1.9)
Betunfair.User.OperationsUser.user_get(2)
Betunfair.User.OperationsUser.user_get(1)
Betunfair.Bet.GestorMarketBet.bet_back(1, 1, 19, 1.3)
Betunfair.Bet.GestorMarketBet.bet_back(1, 1, 19, 80) # cancelar
Betunfair.User.OperationsUser.user_get(1)
Betunfair.Market.OperationsMarket.market_get(1)

# Cancela la última bet
Betunfair.User.OperationsUser.user_bets(1)
Betunfair.User.OperationsUser.user_bets(2)
Betunfair.Market.OperationsMarket.market_pending_lays(1)
Betunfair.Market.OperationsMarket.market_pending_backs(1)
Betunfair.Bet.OperationsBet.bet_get(5)
Betunfair.Bet.OperationsBet.bet_cancel(5) # cancelar
Betunfair.Bet.OperationsBet.bet_get(5)
Betunfair.User.OperationsUser.user_bets(1)
Betunfair.User.OperationsUser.user_get(1)

# Settle
Betunfair.User.OperationsUser.user_get(1)
Betunfair.User.OperationsUser.user_get(2)

Betunfair.Market.OperationsMarket.market_match(1)
Betunfair.Bet.OperationsBet.bet_get(1)
Betunfair.Bet.OperationsBet.bet_get(2)
Betunfair.Bet.OperationsBet.bet_get(3)
Betunfair.Bet.OperationsBet.bet_get(4)
Betunfair.Market.OperationsMarket.market_get(1)
Betunfair.Market.OperationsMarket.market_pending_lays(1)
Betunfair.Market.OperationsMarket.market_pending_backs(1)
Betunfair.Market.OperationsMarket.market_settle(1, false)
Betunfair.Market.OperationsMarket.market_get(1)
Betunfair.User.OperationsUser.user_get(1)
Betunfair.User.OperationsUser.user_get(2)

# FUNCIONA

# Recarga saldos usuarios
Betunfair.User.OperationsUser.user_withdraw(1, 31)
Betunfair.User.OperationsUser.user_withdraw(2, 108)
Betunfair.User.OperationsUser.user_deposit(1, 100)
Betunfair.User.OperationsUser.user_deposit(2, 100)

# Crea el mercado dos
Betunfair.Market.GestorMarket.market_create("M2", "Mercado Ejemplo 2")
Betunfair.Market.GestorMarket.market_list()
Betunfair.Market.GestorMarket.market_list_active()
Betunfair.Market.OperationsMarket.market_get(2)

# Crea apuestas market 2
Betunfair.Bet.GestorMarketBet.bet_back(1, 2, 50, 1.5)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 2, 21, 1.5)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 2, 40, 1.9)
Betunfair.Bet.GestorMarketBet.bet_back(1, 2, 19, 1.3)
Betunfair.User.OperationsUser.user_get(2)
Betunfair.User.OperationsUser.user_get(1)
Betunfair.Market.OperationsMarket.market_bets(2)
Betunfair.Market.OperationsMarket.market_match(2)
Betunfair.Bet.OperationsBet.bet_get(6)
Betunfair.Bet.OperationsBet.bet_get(7)
Betunfair.Bet.OperationsBet.bet_get(8)
Betunfair.Bet.OperationsBet.bet_get(9)
Betunfair.Market.OperationsMarket.market_settle(2, true)
Betunfair.Market.OperationsMarket.market_get(2)
Betunfair.User.OperationsUser.user_get(1)
Betunfair.User.OperationsUser.user_get(2)

# FUNCIONA

# Recarga saldos usuarios
Betunfair.User.OperationsUser.user_withdraw(1, 130.7)
Betunfair.User.OperationsUser.user_withdraw(2, 39)
Betunfair.User.OperationsUser.user_deposit(1, 100)
Betunfair.User.OperationsUser.user_deposit(2, 100)

# Crea el mercado 3
Betunfair.Market.GestorMarket.market_create("M3", "Mercado Ejemplo 3")
Betunfair.Market.GestorMarket.market_list()
Betunfair.Market.GestorMarket.market_list_active()
Betunfair.Market.OperationsMarket.market_get(3)

# Crea apuestas market 3
Betunfair.Bet.GestorMarketBet.bet_back(1, 3, 50, 1.5)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 3, 21, 1.5)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 3, 40, 1.9)
Betunfair.Bet.GestorMarketBet.bet_back(1, 3, 19, 1.3)
Betunfair.Market.OperationsMarket.market_match(3)
Betunfair.Market.OperationsMarket.market_cancel(3)
Betunfair.Bet.OperationsBet.bet_get(10)
Betunfair.Market.OperationsMarket.market_get(3)
Betunfair.User.OperationsUser.user_get(1)
Betunfair.User.OperationsUser.user_get(2)

# FUNCIONA
# Crea el mercado 3
Betunfair.Market.GestorMarket.market_create("M4", "Mercado Ejemplo 4")
Betunfair.Market.GestorMarket.market_list()
Betunfair.Market.GestorMarket.market_list_active()
Betunfair.Market.OperationsMarket.market_get(4)

# Crea apuestas market 3
Betunfair.Bet.GestorMarketBet.bet_back(1, 4, 50, 1.5)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 4, 21, 1.5)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 4, 40, 1.9)
Betunfair.Bet.GestorMarketBet.bet_back(1, 4, 19, 1.3)
Betunfair.Market.OperationsMarket.market_match(4)
Betunfair.Market.OperationsMarket.market_freeze(4)
Betunfair.User.OperationsUser.user_get(1)
Betunfair.User.OperationsUser.user_get(2)

Betunfair.User.OperationsUser.user_withdraw(1, 31)
Betunfair.User.OperationsUser.user_withdraw(2, 69.3)
Betunfair.User.OperationsUser.user_deposit(1, 100)
Betunfair.User.OperationsUser.user_deposit(2, 100)

Betunfair.Market.GestorMarket.market_create("M5", "Mercado Ejemplo 5")
Betunfair.Bet.GestorMarketBet.bet_back(1, 5, 50, 1.5)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 5, 21, 1.5)
Betunfair.Bet.GestorMarketBet.bet_lay(2, 5, 40, 1.9)
Betunfair.Bet.GestorMarketBet.bet_back(1, 5, 19, 1.3)
Betunfair.Market.OperationsMarket.market_match(5)
Betunfair.User.OperationsUser.user_get(1)
Betunfair.User.OperationsUser.user_get(2)
Betunfair.Market.OperationsMarket.market_settle(5, false)
Betunfair.User.OperationsUser.user_get(1)
Betunfair.User.OperationsUser.user_get(2)

```


