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
      @logger = Logger.new(STDOUT, progname: 'ShopifyClient')
      key = ENV['SHOPIFY_API_KEY']
      pswd = ENV['SHOPIFY_API_PW']
      shopname = ENV['SHOP_NAME']
      base_site = "https://#{key}:#{pswd}@#{shopname}.myshopify.com/admin"

      @shopify_base_site = base_site
      @sleep_shopify = ENV['SHOPIFY_SLEEP_TIME']
      @uri = URI.parse(ENV['DATABASE_URL'])
      @conn = PG.connect(@uri.hostname, @uri.port, nil, nil, @uri.path[1..-1], @uri.user, @uri.password)
    end

    def handle_shopify_customers(option)
      params = {
        "option_value" => option,
        "connection" => @uri,
        "shopify_base" => @shopify_base_site,
        "sleep_shopify" => @sleep_shopify
      }

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

    def init_tag_tbl(option)
      @logger.info "Doing shopify customer tag table setup"
      @logger.info "option recieved: #{option.inspect}"

      if option == 'prospect_recurring'
        @cust_tags = ShopifyCustomer.find_by_sql(
          "select * from shopify_customers where tags like
          '%prospect%' and tags like '%recurring_subscription%' and tags not like '%Active Subscriber%';"
          );
      elsif option == 'skip_reset'
        @cust_tags = ShopifyCustomer.find_by_sql(
          "select * from shopify_customers where tags like
          '%skipped%';"
          )
      elsif option == 'inactive'
        @cust_tags = ShopifyCustomer.find_by_sql(
          "select * from shopify_customers where (tags ilike
          '%Inactive Subscriber%' and tags ilike '%prospect%') or
          (tags ilike '%recurring_subscription%' and tags ilike '%Inactive Subscriber%')
          or (tags ilike '%Subscription%card declined%' and tags ilike '%prospect%') or
          (tags ilike '%cancelled%' and tags ilike '%prospect%')"
        )
      else
        raises ArgumentError
      end
      update_tag_tbl(@cust_tags, option)
    end

    def update_tag_tbl(bad_tags, my_opt)
      if (bad_tags.size > 0)
        # Choose which table to process
        if my_opt.to_s == ('inactive' || 'skip_reset')
          my_db_object = ProspectTagFix
        elsif my_opt.to_s == 'prospect_recurring'
          my_db_object = RecurringTagFix
        end
        @logger.debug "table selected: #{my_db_object}"
        @logger.info "#{bad_tags.size} incorrectly tagged customers found in db"

        bad_tags.each do |query_cust|
          myid = query_cust.customer_id
          my_db_object.find_or_create_by(customer_id: myid)
          .update_attributes({
                email: query_cust.email,
                first_name: query_cust.first_name,
                last_name: query_cust.last_name,
                tags: query_cust.tags,
                is_processed: false,
              })
          @logger.info "shopify_id: #{myid} processed"
        end
      end
    end

    def remove_tags(opt_array)
      params = {
        "mytag": opt_array[0],
        "table": opt_array[1],
        "base": @shopify_base_site,
        "sleep": @sleep_shopify
      }
      @logger.info "Starting #{params["mytag"]} tag removal background job.."
      Resque.enqueue(UntagWorker, params)
    end
  end

  class CustomerWorker
    @queue = :shopify_customer
    extend ResqueHelper
    def self.perform(params)
      Resque.logger = Logger.new('logs/customer_pull_resque.log',  10, 1024000)
      Resque.logger.info "Job CustomerWorker started"
      Resque.logger.debug "CustomerWorker#perform params: #{params.inspect}"
      get_shopify_customers_full(params)
    end
  end

  class UntagWorker
    @queue = :tag_removal
    extend ResqueHelper
    def self.perform(params)
      # Resque.logger = Logger.new('logs/resque_helper.log',  10, 1024000)
      Resque.logger = Logger.new(STDOUT,  10, 1024000)
      Resque.logger.info "Job UntagWorker started"
      Resque.logger.debug "UntagWorker#perform params: #{params.inspect}"
      background_remove_tags(params)
    end
  end
# binding.pry
end
