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
echo "Navigating to the project directory..."
cd $PROJECT_NAME > /dev/null 2>&1 || error_exit "Failed to navigate to the project directory."
echo "Successfully navigated to the project directory."
echo

# Install dependencies
echo "Installing dependencies..."
mix deps.get > /dev/null 2>&1 || error_exit "Failed to install dependencies."
echo "Dependencies installed successfully."
echo

# Create and migrate the database
echo "Creating the database..."
mix ecto.create > /dev/null 2>&1 || error_exit "Failed to create the database."
echo "Database created successfully."
echo "Migrating the database..."
mix ecto.migrate > /dev/null 2>&1 || error_exit "Failed to migrate the database."
echo "Database migrated successfully."
echo

# Run tests
echo "Running tests..."
mix test test/betunfair/*  && echo "Tests completed successfully." || echo "Some tests failed."
echo

# Generate project documentation
echo "Generating project documentation..."
mix docs > /dev/null 2>&1 || error_exit "Failed to generate project documentation."
echo "Project documentation generated successfully."
echo

# Start the Phoenix server
echo "Starting the Phoenix server, it may be accessed at http://localhost:4000"
iex -S mix phx.server || error_exit "Failed to start the Phoenix server."

# Output success message
echo "Phoenix server initialized and running. You can access it at http://localhost:4000"
