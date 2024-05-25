

# Project Overview

This part of the project is organized with a clear structure to handle routing, components, and controllers, there are some slight changes. Due to [I](https://github.com/Javisantir) (Javier) was the only one working on the frontend my issues are complete archives not functions. Below is a detailed explanation of each part:

## Router

The router is responsible for defining the URI paths we are using.

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

- **Home, Bets, and Profile**: 
  - These directories contain the specific HTML for each section.
  
- **Controllers**: 
  - This is where the functions from the API are used.

- **Pages**: 
    - This ones are just render to tell where are the HTML.

---
The rest is like a normal phoenix project. For using the GUI just click [localhost](http://localhost:4000) after doing mix phx.server,  the two buttons are the 2 pages the user will see after login in.