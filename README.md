# shopify_db_utility_app
A standalone utility app made for api/database synchronization to preserve production server resources
by delegating low level tasks to an aux server based app.

### Prerequisites

```
redis
postgresql
ruby 2.5
bundler
rvm
```

### Installing

Clone the repo onto your local machine

```
$ git clone git@github.com:Nevillealee/shopify_db_utility_app.git
```

Install gemfile

```
$ bundle install
```

cd into app dir and create .env file with the following:

```
DATABSE_URL= "postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]"
TEST_DB_URL= "[SEE ABOVE EXAMPLE]"
SHOPIFY_API_KEY="[your private app shopify api key]"
SHOPIFY_API_PW="[your private app shopify api pw]"
SHOP_NAME="[name of your shopify store without '.myshopify.com' suffix]"
SHOPIFY_SLEEP_TIME=[number of seconds to wait when api limit reached]
REDIS_URL="[redis://[:PASSWORD@]HOST[:PORT]]"
```
Logging

```
Change Logger output to STDOUT when working in development
and back to "logs/*.log" when in production for both [resque_helper.rb] and [app.rb] files
```

Set up database

```
$ rake db:create
$ rake db:migrate
```
Open another terminal tab (in same dir)

```
$ rake resque:work QUEUE='*'
```
Start redis server manually if redis not already installed/running as daemon
in another terminal tab

```
$ redis-server path/to/redis.conf

  (macOS default_path: /usr/local/etc/redis.conf)
  (linux default_path: /etc/redis.conf)
```
Run initial data pull from shopify into db

```
$ rake shopify:customer_pull[full_pull]
```

## Built With

* [sinatra](http://sinatrarb.com/) - The web framework used
* [bundler](https://bundler.io/) - Dependency Management
* [rvm](https://rvm.io/) - Package Management


## Authors

* **Neville Lee** - *Initial work* - [Nevillealee](https://github.com/nevillealee)
