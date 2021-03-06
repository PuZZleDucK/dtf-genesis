
# About

This is the @PuZZleDucK fork of the CfA @ DTF project

## Aims

1. Get <strike>tests back on track</strike>
2. Get <strike>CI/CD back on track (semaphore / codeship</strike>)
  * [ ![Codeship Status for PuZZleDucK/dtf-genesis](https://app.codeship.com/projects/df1ac380-cf8a-0134-c966-2ef68c3264a8/status?branch=master)](https://app.codeship.com/projects/200923)
  * [![Build Status](https://semaphoreci.com/api/v1/puzzleduck/dtf-genesis/branches/master/badge.svg)](https://semaphoreci.com/puzzleduck/dtf-genesis)
3. <strike>Store all contract types</strike>
4. Store all revisions and ocid
5. Automate validity checking in new/updated contracts
6. Simplify DB/UI
7. Correct documentation

# CfA & DTF Genesis

We aim to provide transparency of construction contracts.

A platform where anyone who wants insights on government projects can subscribe and participate actively and sharing the information collected to preferred social media.

A place for public to be aware and be inspired of the upcoming projects and infrastructure that will be implemented on their areas.

# Setup
1.  Install rails:
    [for Windows or Mac](http://railsinstaller.org/en)
    [for Linux](http://railsapps.github.io/installrubyonrails-ubuntu.html)

2. Install PostgreSQL database

  * Windows
    * Download [postgresql](http://www.enterprisedb.com/products-services-training/pgdownload#windows)
    * Take note of port setting (5432 is default)
    * Run postgresql pgAdmin 4 GUI
    * "object menu" --> "properties" --> "connection"
    * Create a user and take note of the *username* and *password* in the postgres database

  * Linux
    * In a terminal run
```bash
sudo apt-get install postgresql postgresql-server-dev-all
sudo su - postgres
createdb genesis_development
psql
```

    * Then in SQL prompt:
```sql
CREATE USER genesis WITH PASSWORD 'q1w2e3r4t5';
ALTER USER genesis CREATEDB;
```

3. Create/Locate a suitable local folder like "Sites" for development

4. Open terminal ("Command Prompt With Ruby On Rails") and execute the following tasks


```bash
git clone https://github.com/CodeforAustralia/dtf-genesis.git
cd dtf-genesis
```

5. Edit *database.yml* file with appropriate *username* and *password* for the development database (Ex. genesis_development) from "config" folder

6. Then run the commands:

```bash
bundle install
rails db:create db:migrate
rails db:migrate RAILS_ENV=test
rails test
rails server
```

7. Open your browser and you should be able to see your application by entering the url `localhost:3000`

8. Create active admin user locally
Run this commands at terminal:
```bash
    rails c  # opens up rails console
    u = User.new
    u.email = "admin@example.com"
    u.password = "password"
    u.password_confirmation = "password"
    u.save
```

9. Run required database setup tasks (prefix with ```heroku run``` to run on production)

```bash
rails db:migrate
bundle exec rake db:seed
bundle exec rake migrate:contract_status
bundle exec rake migrate:contract_types
bundle exec rake migrate:agency
bundle exec rake migrate:value_types
bundle exec rake migrate:unspsc
```

10. On heroku you may need to add a phantomjs buildpack

```
heroku buildpacks:add https://github.com/stomita/heroku-buildpack-phantomjs
```

11. Now you should be able to trigger the scraper with

```bash
bundle exec rake scrape:new
bundle exec rake scrape:update 
```

