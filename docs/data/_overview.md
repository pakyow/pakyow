---
name: Databases
desc: Using Sequel &amp; Postgres for database access.
guide: true
---

Pakyow will play nice with most Ruby object-relational mappers (ORMs). We recommend using [Sequel](https://github.com/jeremyevans/sequel). This guide will teach you how to get Sequel working in your Pakyow project.

## Configuring Sequel

First, add Sequel as a dependency of your project. Add the following code to your `Gemfile`:

```ruby
gem 'sequel'
```

Run `bundle install` from the command line and you're good to go.

Next, we need Pakyow to connect to the database on boot. Open `app/setup.rb` and add the following code to the `configure :global` block:

```ruby
$db = Sequel.connect(url_or_options)
```

Replace `url_or_options` with a connect string or connection options ([read more here](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html)).

### Using Dotenv for Configuration

We recommend using a connect string defined in an environment variable named `DATABASE_URL`. A good way to define environment variables is with [dotenv](https://github.com/bkeepers/dotenv).

To use dotenv, first add the following code to your `Gemfile`:

```ruby
gem 'dotenv', groups: [:development, :test]

group :production do
  gem 'dotenv-deployment'
end
```

Next, add the following code right after `Bundler.require` in the `configure :global` block of `app/setup.rb`:

```ruby
Dotenv.load
```

Create a `.env` file in the root of your project and add the following:

```
DATABASE_URL=connect_string
```

Replace `connect_string` with the connection string for your environment and database. If you're using Postgres, it would look something like this:

```
DATABASE_URL=postgres://localhost/my-database-name
```

Add `.env` to `.gitignore` so that it's accessible only by your environment.

## Writing &amp; Running Migrations

Sequel uses migrations to create tables and make other changes to your database.

To use migrations, first create a `migrations` folder in the root directory of your project. This is where your migration files will live. For example, to create a table we could create a `migrations/001_create_users.rb` file that contains the following code:

```ruby
Sequel.migration do
  up do
    create_table :users do
      primary_key :id
      String :name
      String :email
    end
  end

  down do
    drop_table :users
  end
end
```

Run the migrations against a database like this:

```
bundle exec sequel -m ./migrations {connect_string}
```

You can read more about migrations [here](http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html).

## Defining &amp; Using Models

Models can be used to store and fetch data from the database. Building on the example above, we can create a `User` model to create and access users. Sequel makes this really easy, just create a `app/lib/models/user.rb` file with the following code:

```ruby
class User < Sequel::Model
end
```

Now you can access user data from anywhere in your project like this:

```ruby
users = User.all
```

You can read more about models [here](http://sequel.jeremyevans.net/rdoc/files/README_rdoc.html#label-Sequel+Models).

## Adding Convenient Rake Tasks

If you're using Postgres (and you probably should be), we recommend using the [pakyow-rake-db](https://github.com/bryanp/pakyow-rake-db) gem. It adds several [rake](https://github.com/ruby/rake) tasks to make it easier to do things to your database:

### db:drop

Drops the project's configured database.

### db:create

Creates the project's configured database.

### db:migrate[version]

Runs migrations against the project's configured database (all the way through or to `version`).

### db:seed

Runs `config/seeds.rb` to load data into the project's configured database.

### db:setup

Runs `db:create`, `db:migrate`, and `db:seed`.

### db:reset

Runs `db:drop` and `db:setup`.

### db:migration:create[name]

Creates a new migration with provided `name`, automatically prefixed.

## Presenting Data

Before we can present data we should create some for testing. To keep it easy for this guide, we'll use console. Run `pakyow console` and enter the following commands:

```
irb(main):001:0> User.create(name: 'User 1', body: 'user1@pakyow.org')
irb(main):002:0> User.create(name: 'User 2', body: 'user2@pakyow.org')
irb(main):003:0> User.create(name: 'User 3', body: 'user3@pakyow.org')
```

Now we have three users in our database. Type `exit` and hit enter to exit console.

Let's create a view that we'll use to present our users. Create an `index.html` file in `app/views`. Add the following HTML:

```html
<div data-scope="user">
  <h1 data-prop="name">
    This is the user name
  </h1>

  <p data-prop="email">
    User email goes here
  </p>
</div>
```

Run `bundle exec pakyow server` to start the server, then navigate to [localhost:3000](http://localhost:3000) to see the new view prototype. Now let's bind our user data to it. Open `app/lib/routes.rb` and define a default route. Here's what it should look like:

```ruby
Pakyow::App.routes do
  default do
    view.scope(:post).apply(User.all)
  end
end
```

Reload your browser and you'll see the three users we created earlier.

---

Hopefully this guide has helped you get going using a database in your Pakyow project.
