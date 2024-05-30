# BetUnfair

Betting Exchange Platform written in Elixir for the Programming Scalable Systems subject @ Polythetnic University of Madrid

This project includes a GUI made with the Phoenix framework to interact with the internal API.

![web GUI](pictures/web.jpg)

## Dependencies:

- psql (15.5) o versiones superiores.
- elixir (1.14) o versiones superiores
- phoenix (1.7.12)

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

## PSQL setup
In case psql is not already set up, it is needed to follow this steps

#### Step 1: Update Package List
```sh
sudo apt-get update
```
#### Step 2: Step 2: Install PostgreSQL

```sh
sudo apt-get install postgresql
```
And verify the installation.
```sh
psql --version
```
#### Step 3: Verify that psql user exist
```sh
psql -h hostname -U postgres -d dbname
```
If psql user does not exist, we need to create it:
```sh
CREATE USER postgres WITH PASSWORD 'postgres';
```
