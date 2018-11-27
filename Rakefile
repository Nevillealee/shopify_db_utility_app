require 'dotenv'
Dotenv.load
require 'redis'
require 'resque'
Resque.redis = Redis.new(url: ENV['REDIS_URL'])
require 'active_record'
require 'sinatra/activerecord/rake'
require 'resque/tasks'
require_relative 'app.rb'
require 'pry'

desc 'Pull shopify customers in db'
task :shopify_customer_pull, [:args] do |t, args|
  ShopifyClient::Customer.new.handle_shopify_customers(*args)
end
