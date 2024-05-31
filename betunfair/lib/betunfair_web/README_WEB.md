

# Project Overview

This part of the project is organized with a clear structure to handle routing, components, and controllers, there are some slight changes. Due to [I](https://github.com/Javisantir) (Javier) was the only one working on the frontend my issues are complete archives not functions. Below is a detailed explanation of each part:

## Router

The router is responsible for defining the URI paths we are using. It is like an API, but controlled by the phoenix framework.

### GET Operations
| Path                 | Controller          | Action         | Description                                                 |
|----------------------|---------------------|----------------|-------------------------------------------------------------|
| `/`                  | PageController      | home           | Renders the home page of the application.                   |
| `/users/:id/profile` | ProfileController   | profile        | Displays the profile page for a specific user.              |
| `/markets`           | MarketsController   | list_markets   | Retrieves and displays a list of all available betting markets. |
| `/markets/:id/bets`  | BetsController      | bets           | Shows the bets available for a specific market.             |

### POST Operations
| Path               | Controller         | Action          | Description                                     |
|--------------------|--------------------|-----------------|-------------------------------------------------|
| `/add_funds`       | ProfileController  | add_funds       | Handles the operation to add funds to a user’s account. |
| `/remove_funds`    | ProfileController  | withdraw_funds  | Allows users to withdraw funds from their account.  |
| `/bets/cancel`     | ProfileController  | cancel_bet      | Provides functionality for users to cancel an existing bet. |
| `/bets/create_bet` | BetsController     | create_bet      | Enables users to place new bets on available markets.      |


## Components and Controllers

### Components

This directory contains the main parts of the HTML:

- **App**: 
  - This is the navbar (header).
  - It also contains the main section where other `.heex` files will be included.
  - It appears on every page except the home page.
  
- **Root**: 
  - This is one of the most important parts of the frontend as it includes the head of the HTML.

### Controllers

This directory contains the different HTML files and their corresponding controllers:

- **Home, Bets, Markets, and Profile**: 
  - These directories contain the specific HTML for each section.
  
- **Controllers**: 
  - This is where the functions from the API are used.

- **Pages**: 
    - This ones are just render to tell where are the HTML.

---
The rest is like a normal phoenix project. For using the GUI just click [localhost](http://localhost:4000) after doing mix phx.server,  the two buttons are the 2 pages the user will see after login in.