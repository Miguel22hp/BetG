# Create users 1 y 2 y check their operations
Betunfair.User.GestorUser.user_create("1", "U1") # Creates user 1
Supervisor.which_children(:user_supervisor) # Checks ":user_supervisor" children processes
Betunfair.User.OperationsUser.user_deposit(1, 200) # Deposits 200 in the user's 2 money
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_withdraw(1, 100) # Withdraws 100 from the user's 1 money
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.GestorUser.user_create("2", "U2") # Creates user 2
Betunfair.User.OperationsUser.user_deposit(2, 100) # Deposits 100 in the user's 2 money
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information

# Create market 1
Betunfair.Market.GestorMarket.market_list() # Get the list of markets
Betunfair.Market.GestorMarket.market_list_active() # Get the list of active markets
Betunfair.Market.GestorMarket.market_create("M1", "Mercado Ejemplo 1") # Create an active market
Betunfair.Market.GestorMarket.market_list() # Get the list of markets
Betunfair.Market.GestorMarket.market_list_active() # Get the list of active markets
Supervisor.which_children(:market_supervisor) # Checks ":market_supervisor" children processes
Supervisor.which_children(:bet_supervisor) # Checks ":bet_supervisor" children processes
Supervisor.which_children(:matched_supervisor) # Checks ":matched_supervisor" children processes

# Crea apuestas del user 1 para el mercado 1
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.Bet.GestorMarketBet.bet_back(1, 1, 50, 1.5) # Create a back bet for user 1 in market 1
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information
Betunfair.Bet.GestorMarketBet.bet_lay(2, 1, 21, 1.5) # Create a lay bet for user 1 in market 1
Betunfair.Bet.GestorMarketBet.bet_lay(2, 1, 40, 1.9) # Create a lay bet for user 1 in market 1
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.Bet.GestorMarketBet.bet_back(1, 1, 19, 1.3) # Create a back bet for user 1 in market 1
Betunfair.Bet.GestorMarketBet.bet_back(1, 1, 19, 80) # Create a back bet for user 1 in market 1. This one you will cancel
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.Market.OperationsMarket.market_get(1) # Gets market 1 information

# Cancela la última bet
Betunfair.User.OperationsUser.user_bets(1) # Get a list of all bets of user 1
Betunfair.User.OperationsUser.user_bets(2) # Get a list of all bets of user 2
Betunfair.Market.OperationsMarket.market_pending_lays(1) # Get the lay bets in market 1 not entirely matched
Betunfair.Market.OperationsMarket.market_pending_backs(1) # Get the back bets in market 1 not entirely matched
Betunfair.Bet.OperationsBet.bet_get(5) # Get the information about bet 5
Betunfair.Bet.OperationsBet.bet_cancel(5) # Bet gets cancelled
Betunfair.Bet.OperationsBet.bet_get(5) # Get the information about bet 5
Betunfair.User.OperationsUser.user_bets(1) # Gets user 1 bets
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information

# Settle
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information

Betunfair.Market.OperationsMarket.market_match(1) # Match the bets in market 1
Betunfair.Bet.OperationsBet.bet_get(1) # Get the information about bet 1
Betunfair.Bet.OperationsBet.bet_get(2) # Get the information about bet 2
Betunfair.Bet.OperationsBet.bet_get(3) # Get the information about bet 3
Betunfair.Bet.OperationsBet.bet_get(4) # Get the information about bet 4
Betunfair.Market.OperationsMarket.market_get(1) # Gets market 1 information
Betunfair.Market.OperationsMarket.market_pending_lays(1) # Get the lay bets in market 1 not entirely matched
Betunfair.Market.OperationsMarket.market_pending_backs(1) # Get the back bets in market 1 not entirely matched
Betunfair.Market.OperationsMarket.market_settle(1, false) # Settle the market so lay wins
Betunfair.Market.OperationsMarket.market_get(1) # Gets market 1 information
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information

# Recarga saldos usuarios
Betunfair.User.OperationsUser.user_withdraw(1, 31) # Withdraw the ammount of money left in user 1
Betunfair.User.OperationsUser.user_withdraw(2, 138.3)  # Withdraw the ammount of money left in user 2
Betunfair.User.OperationsUser.user_deposit(1, 100) # Deposits 100 in the user's 1 money
Betunfair.User.OperationsUser.user_deposit(2, 100) # Deposits 100 in the user's 2 money

# Crea el mercado dos
Betunfair.Market.GestorMarket.market_create("M2", "Mercado Ejemplo 2") # Create an active market
Betunfair.Market.GestorMarket.market_list() # Get the list of markets
Betunfair.Market.GestorMarket.market_list_active() # Get the list of active markets
Betunfair.Market.OperationsMarket.market_get(2) # Gets market 2 information

# Crea apuestas market 2
Betunfair.Bet.GestorMarketBet.bet_back(1, 2, 50, 1.5) # Create a back bet for user 1 in market 2
Betunfair.Bet.GestorMarketBet.bet_lay(2, 2, 21, 1.5) # Create a lay bet for user 1 in market 2
Betunfair.Bet.GestorMarketBet.bet_lay(2, 2, 40, 1.9) # Create a lay bet for user 1 in market 2
Betunfair.Bet.GestorMarketBet.bet_back(1, 2, 19, 1.3) # Create a back bet for user 1 in market 2
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.Market.OperationsMarket.market_bets(2) # Get all market 2 bets
Betunfair.Market.OperationsMarket.market_match(2) # Match the bets in market 2
Betunfair.Bet.OperationsBet.bet_get(6) # Get the information about bet 6
Betunfair.Bet.OperationsBet.bet_get(7) # Get the information about bet 7
Betunfair.Bet.OperationsBet.bet_get(8) # Get the information about bet 8
Betunfair.Bet.OperationsBet.bet_get(9) # Get the information about bet 9
Betunfair.Market.OperationsMarket.market_settle(2, true) # Settle the market so back wins
Betunfair.Market.OperationsMarket.market_get(2) # Gets market 2 information
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information

# Recarga saldos usuarios
Betunfair.User.OperationsUser.user_withdraw(1, 130.7) # Withdraw the ammount of money left in user 1
Betunfair.User.OperationsUser.user_withdraw(2, 69.3) # Withdraw the ammount of money left in user 2
Betunfair.User.OperationsUser.user_deposit(1, 100) # Deposits 100 in the user's 1 money
Betunfair.User.OperationsUser.user_deposit(2, 100) # Deposits 100 in the user's 2 money

# Crea el mercado 3
Betunfair.Market.GestorMarket.market_create("M3", "Mercado Ejemplo 3") # Create an active market
Betunfair.Market.GestorMarket.market_list() # Get the list of markets
Betunfair.Market.GestorMarket.market_list_active() # Get the list of active markets
Betunfair.Market.OperationsMarket.market_get(3) # Gets market 3 information

# Crea apuestas market 3
Betunfair.Bet.GestorMarketBet.bet_back(1, 3, 50, 1.5) # Create a back bet for user 1 in market 3
Betunfair.Bet.GestorMarketBet.bet_lay(2, 3, 21, 1.5) # Create a lay bet for user 1 in market 3
Betunfair.Bet.GestorMarketBet.bet_lay(2, 3, 40, 1.9) # Create a lay bet for user 1 in market 3
Betunfair.Bet.GestorMarketBet.bet_back(1, 3, 19, 1.3) # Create a back bet for user 1 in market 3
Betunfair.Market.OperationsMarket.market_match(3) # Match the bets in market 3
Betunfair.Market.OperationsMarket.market_cancel(3) # Cancels the market
Betunfair.Bet.OperationsBet.bet_get(10) # Get the information about bet 10
Betunfair.Market.OperationsMarket.market_get(3) # Gets market 3 information
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information

# Crea el mercado 3
Betunfair.Market.GestorMarket.market_create("M4", "Mercado Ejemplo 4") # Create an active market
Betunfair.Market.GestorMarket.market_list() # Get the list of markets
Betunfair.Market.GestorMarket.market_list_active() # Get the list of active markets
Betunfair.Market.OperationsMarket.market_get(4) # Gets market 4 information

# Crea apuestas market 3
Betunfair.Bet.GestorMarketBet.bet_back(1, 4, 50, 1.5) # Create a back bet for user 1 in market 4
Betunfair.Bet.GestorMarketBet.bet_lay(2, 4, 21, 1.5) # Create a lay bet for user 1 in market 4
Betunfair.Bet.GestorMarketBet.bet_lay(2, 4, 40, 1.9) # Create a lay bet for user 1 in market 4
Betunfair.Bet.GestorMarketBet.bet_back(1, 4, 19, 1.3) # Create a back bet for user 1 in market 4
Betunfair.Market.OperationsMarket.market_match(4) # Match the bets in market 4
Betunfair.Market.OperationsMarket.market_freeze(4) # Frezzes the market
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information

Betunfair.User.OperationsUser.user_withdraw(1, 31) # Withdraw the ammount of money left in user 1
Betunfair.User.OperationsUser.user_withdraw(2, 69.3) # Withdraw the ammount of money left in user 1
Betunfair.User.OperationsUser.user_deposit(1, 100) # Deposits 100 in the user's 1 money
Betunfair.User.OperationsUser.user_deposit(2, 100) # Deposits 100 in the user's 2 money

Betunfair.Market.GestorMarket.market_create("M5", "Mercado Ejemplo 5") # Create an active market
Betunfair.Bet.GestorMarketBet.bet_back(1, 5, 50, 1.5) # Create a back bet for user 1 in market 5
Betunfair.Bet.GestorMarketBet.bet_lay(2, 5, 21, 1.5) # Create a lay bet for user 1 in market 5
Betunfair.Bet.GestorMarketBet.bet_lay(2, 5, 40, 1.9) # Create a lay bet for user 1 in market 5
Betunfair.Bet.GestorMarketBet.bet_back(1, 5, 19, 1.3) # Create a back bet for user 1 in market 5
Betunfair.Market.OperationsMarket.market_match(5) # Match the bets in market 5
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information
Betunfair.Market.OperationsMarket.market_settle(5, false) # Settle the market so lay wins
Betunfair.User.OperationsUser.user_get(1) # Gets user 1 information
Betunfair.User.OperationsUser.user_get(2) # Gets user 2 information
