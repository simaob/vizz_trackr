## Dependencies

- Ruby 2.6.3
- Rails 6.0.0.rc2
- PostgreSQL 10.x

## Setting up your local environment

- `git clone git@github.com:Vizzuality/vizz_trackr.git`
- `cd vizz_trackr`
- `bundle install`
- `rails db:create`
- `rails db:migrate`

## Starting the project

- `rails server`
- point your browser to `http://localhost:3000`

## Setting up .env file

Before upping your Rails server, you should also create a `.env` file with the necessary env variables. These are stated in the `.env.sample` file, so you only need to copy the file and fill the variables appropriately.

## Getting a User setup and more data

You will need to create a user to be able to login and add data to the tool.
You will need to do that via the console, as registration of new users via the interface
is currently disabled, to do so, type this into your terminal:

`rails console`
`User.create(email: "youremail@yourorg.yourdomain", password: "your_password", password_confirmation: "your_password")`

After this you'll be able to login with those details!

