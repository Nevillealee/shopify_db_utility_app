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

  desc 'Set up tag table [prospect_recurring] or [skip_reset]'
  task :init_tag_tbl, [:args] do |t, args|
    ShopifyClient::Customer.new.init_tag_tbl(*args)
  end

  desc 'Remove [option] tag from customers'
  task :remove_tag, [:args] do |t, args|
    ShopifyClient::Customer.new.remove_tags(*args)
  end
end
