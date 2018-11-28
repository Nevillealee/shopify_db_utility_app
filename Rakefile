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

namespace :shopify do
  desc 'Pull shopify customers in db'
  task :customer_pull, [:args] do |t, args|
    ShopifyClient::Customer.new.handle_shopify_customers(*args)
  end

  desc 'Set up shopify customer tag table'
  task :tag_table_setup do
    ShopifyClient::Customer.new.setup_tag_table
  end

  desc 'Remove false tag from option arg'
  task :remove_tag, [:args] do |t, args|
    ShopifyClient::Customer.new.remove_false_tag(*args)
  end
end
