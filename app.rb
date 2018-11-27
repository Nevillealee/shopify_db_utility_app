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
      # TODO(Neville) change STDOUT to 'logs/customer_pull_resque.log' for production
      @logger = Logger.new(STDOUT, progname: 'ShopifyClient', level: 'INFO')
      @shopify_base_site = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_API_PW']}@#{ENV['SHOP_NAME']}.myshopify.com/admin"
      @sleep_shopify = ENV['SHOPIFY_SLEEP_TIME']
      @uri = URI.parse(ENV['DATABASE_URL'])
      @conn = PG.connect(@uri.hostname, @uri.port, nil, nil, @uri.path[1..-1], @uri.user, @uri.password)
    end

    def handle_shopify_customers(option)
      params = {"option_value" => option, "connection" => @uri, "shopify_base" => @shopify_base_site, "sleep_shopify" => @sleep_shopify}
      if option == "full_pull"
        @logger.info "Doing full pull of shopify customers"
        #delete tables and do full pull
        Resque.enqueue(CustomerWorker, params)
      elsif option == "yesterday"
        @logger.info "Doing partial pull of shopify customers since yesterday"
        Resque.enqueue(CustomerWorker, params)
      else
        @logger.error "sorry, cannot understand option #{option}, doing nothing."
      end
    end

  end

  class CustomerWorker
    @queue = :shopify_customer
    extend ResqueHelper
    def self.perform(params)
      Resque.logger = Logger.new(STDOUT,  10, 1024000)
      Resque.logger.info "Job CustomerWorker started"
      Resque.logger.debug "CustomerWorker#perform params: #{params.inspect}"
      get_shopify_customers_full(params)
    end
  end

end
