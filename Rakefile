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

desc 'list current shopify customers'
task :list_customers do |t|
    ShopifyClient::Customer.new.print_list
end
