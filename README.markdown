# Introduction

Pakyow is an open-source framework for building web apps in Ruby. It enables 
you to get straight to work by letting data be data, views be views, and 
code be code.

## Designer-friendly Views
Views are 100% HTML, no template language required. The view has finally been 
freed from logic.

## Sturdy Prototypes
A view knows what it presents. Use this to create powerful connections between 
business logic and views.

## Intelligent Connections
Prototype an app by building the views first. Then write the view logic 
without changing a single view.

Pakyow consists of two gems: pakyow-core and pakyow-presenter. Core handles 
routing requests to an app's business logic. Presenter gives an app the 
ability to have a presentation layer and provides mechanisms for the view
manipulation and data binding. Core can operate independently of Pakyow 
Presenter for cases where an app doesn't need a presentation layer.

# Getting Started

1. Install Pakyow:

    `gem install pakyow`

2. Create a new Pakyow application from the command prompt:

    `pakyow new webapp`

3. Move to the "webapp" directory and start the application:

    `cd webapp; pakyow server`
    
4. You'll find the application running here: http://localhost:3000

# Next Steps

The following resources might be handy:

Website:
http://pakyow.com

Manual:
http://pakyow.com/manual

Code:
http://github.com/metabahn/pakyow
