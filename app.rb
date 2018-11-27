require 'dotenv'
Dotenv.load
require 'httparty'
require 'resque'
require 'sinatra'
require 'active_record'
require "sinatra/activerecord"
require_relative 'resque_helper'
Dir["./models/*.rb"].each {|file| require file }
require 'pry'

module ShopifyClient
  class Customer
    def initialize
      # Dotenv.load
      @uri = URI.parse(ENV['DATABASE_URL'])
      @conn = PG.connect(@uri.hostname, @uri.port, nil, nil, @uri.path[1..-1], @uri.user, @uri.password)
    end

    def print_list
      puts "method started"
      all_customers = ShopifyCustomer.all
      all_customers.each {|cust| puts cust.inspect}
    end
  end
end
