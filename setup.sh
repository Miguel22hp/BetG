#!/bin/bash

# Define project name
PROJECT_NAME="betunfair"

# Function to display an error message and exit
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# # Check for Elixir
# if ! command -v elixir &> /dev/null; then
#     error_exit "Elixir is not installed. Please install Elixir before running this script."
# fi

# # Check for Phoenix
# if ! mix help | grep phx.new &> /dev/null; then
#     error_exit "Phoenix is not installed. Please install Phoenix by running: mix archive.install hex phx_new"
# fi

# Navigate to the project directory
cd $PROJECT_NAME || error_exit "Failed to navigate to the project directory."

# Install dependencies
mix deps.get || error_exit "Failed to install dependencies."

# Create and migrate the database
mix ecto.create || error_exit "Failed to create the database."
mix ecto.migrate || error_exit "Failed to migrate the database."

# Run tests
mix test test/betunfair/*

# Start the Phoenix server
iex -S mix phx.server || error_exit "Failed to start the Phoenix server."

# Output success message
echo "Phoenix server initialized and running. You can access it at http://localhost:4000"

