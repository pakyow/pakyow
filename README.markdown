[![Build Status](https://travis-ci.org/metabahn/pakyow.png)](https://travis-ci.org/metabahn/pakyow)

# Introduction

Pakyow is an open-source framework for building web apps in Ruby. It enables
you to get straight to work by letting data be data, views be views, and
code be code.

## Designer-friendly Views
In Pakyow, views are purely structural and contain no logic, keeping the view
focused on it's job of presentation. No special markup is required in the
view. This means the designer can build the presentation layer for an app in
their own environment.

## Sturdy Prototypes
View construction happens automatically, which means a working, navigable
front-end can be created without any back-end code. Business logic is added
later without any changes to the front-end, eliminating resistance and
keeping development moving forward.

## Intelligent Connections
Data awareness is built into views, meaning a view knows what it presents.
Data is bound in from the back-end without requiring a single change to the
view. Roles and responsibilities remain clear throughout the development process.

--

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
