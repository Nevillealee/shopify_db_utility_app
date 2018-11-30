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
# TODO(Neville Lee) add api limit rescue statements
module ShopifyClient
  class Customer
    def initialize
      # TODO(Neville) change STDOUT to 'logs/customer_pull_resque.log' for production
      @logger = Logger.new(STDOUT, progname: 'ShopifyClient', level: 'INFO')
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
      # option = skip_set or prospect_recurring
      @logger.info "Doing shopify customer tag table setup"
      @logger.info "option recieved: #{option.inspect}"
      if option == 'prospect_recurring'
        @cust_tags = ShopifyCustomer.find_by_sql(
          "select * from shopify_customers where tags like
          '%prospect%' and tags like '%recurring_subscription%';"
          );
      elsif option == 'skip_reset'
        @cust_tags = ShopifyCustomer.find_by_sql(
          "select * from shopify_customers where tags like
          '%skipped%';"
          );
      else
        raises ArgumentError
      end
      update_tag_tbl(@cust_tags)
    end

    def update_tag_tbl(bad_tags)
      if (bad_tags.size > 0)
        @logger.info "#{bad_tags.size} incorrectly tagged customers found in db"
        bad_tags.each do |query_cust|
          myid = query_cust.customer_id
      ShopifyCustomerTagFix.find_or_create_by(customer_id: myid)
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

    def remove_tags(option)
      @logger.info "tag to be removed from customers in shopify_customer_tag_fixes table: #{option}"
      tag_fixes = ShopifyCustomerTagFix.where(is_processed: false)
      tag_fixes.each do |tag_tbl_cust|
        shopify_id = tag_tbl_cust.customer_id
        ShopifyAPI::Base.site = @shopify_base_site
        @logger.info "Handling shopify_customer_id: #{shopify_id}"

        begin
          customer_obj = ShopifyAPI::Customer.find(shopify_id)
        rescue StandardError => e
          @logger.error "#{e.inspect}"
          next
        end

        my_tags = customer_obj.tags.split(",")
        my_tags.map! {|x| x.strip}
        @logger.info "tags before: #{customer_obj.tags.inspect}"
        changes_made = false

        my_tags.each do |x|
          if x.include?(option.to_s)
            my_tags.delete(x)
            changes_made = true
          end
        end

        if changes_made
          customer_obj.tags = my_tags.join(",")
          customer_obj.save!
          tag_tbl_cust.tags = my_tags.join(",")
          @logger.info "changes made, tags after: #{customer_obj.tags.inspect}"
          tag_tbl_cust.is_processed = true
          tag_tbl_cust.save!
          @logger.info "#{shopify_id} is_processed value now = #{tag_tbl_cust.is_processed}"
        else
          @logger.error "No changes made, #{option} tag not found in: #{customer_obj.tags.inspect}"
        end
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
# binding.pry
end
