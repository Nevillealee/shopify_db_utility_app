require 'dotenv'
Dotenv.load
require 'httparty'
require 'resque'
require 'sinatra'
require 'active_record'
require "sinatra/activerecord"
require 'shopify_api'
require_relative 'resque_helper'
Dir["./models/*.rb"].each {|file| require file }
require 'pry'
module ShopifyClient
  class Customer
    def initialize
      @logger = Logger.new('logs/customer_pull_resque.log', 10, 1024000)
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
          "select * from shopify_customers where ((tags ilike
          '%prospect%' and tags ilike '%recurring_subscription%') and tags not ilike '%Active Subscriber%')
          or (tags ilike '%recurring_subscription%' and tags ilike '%Inactive Subscriber%');"
        )
      elsif option == 'skip_reset'
        @cust_tags = ShopifyCustomer.find_by_sql(
          "select * from shopify_customers where tags like
          '%skipped%';"
          )
      elsif option == 'inactive'
        @cust_tags = ShopifyCustomer.find_by_sql(
          "select * from shopify_customers where (tags ilike
          '%Inactive Subscriber%' and tags ilike '%prospect%')
          or (tags ilike '%Subscription%card declined%' and tags ilike '%prospect%') or
          (tags ilike '%cancelled%' and tags ilike '%prospect%')"
        )
      else
        raise ArgumentError
      end
      update_tag_tbl(@cust_tags, option)
    end

    def update_tag_tbl(bad_tags, my_opt)
      if (bad_tags.size > 0)
        # Choose which table to process
        if my_opt.to_s == 'skip_reset'
          my_db_object = ProspectTagFix
        elsif my_opt.to_s == 'inactive'
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
          @logger.info "shopify_id: #{myid} ready to fix"
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

  # pull shopify customers into db
  class CustomerWorker
    @queue = :shopify_customer
    extend ResqueHelper
    def self.perform(params)
      Resque.logger = Logger.new('logs/customer_pull_resque.log', 10, 1024000)
      Resque.logger.info "Job CustomerWorker started"
      Resque.logger.debug "CustomerWorker#perform params: #{params.inspect}"
      get_shopify_customers_full(params)
    end
  end

  class UntagWorker
    @queue = :tag_removal
    extend ResqueHelper
    def self.perform(params)
      Resque.logger = Logger.new('logs/resque_helper.log', 10, 1024000)
      # Resque.logger = Logger.new(STDOUT,  10, 1024000)
      Resque.logger.info "Job UntagWorker started"
      Resque.logger.debug "UntagWorker#perform params: #{params.inspect}"
      background_remove_tags(params)
    end
  end

  class RecurringTagWorker
    @queue = :false_recurring_fix
    def self.perform
      key = ENV['SHOPIFY_API_KEY']
      pswd = ENV['SHOPIFY_API_PW']
      shopname = ENV['SHOP_NAME']
      base_site = "https://#{key}:#{pswd}@#{shopname}.myshopify.com/admin"

      Resque.logger = Logger.new('logs/false_recurring_fix.log', 10, 1024000)
      Resque.logger.info "Job RecurringTagWorker started"
      # added 8/27/19 to remove false recurring_subscription tags since "Active Subscriber" unreliable
      # as of 2019. discussed in meeting 8/26/19
      cust_list = ShopifyCustomer.find_by_sql("select DISTINCT sc.* from shopify_customers sc INNER JOIN
        customers cust  ON sc.customer_id = cust.shopify_customer_id INNER JOIN subscriptions
        sub ON cust.customer_id = sub.customer_id where sub.status <> 'ACTIVE' AND sc.tags
        ilike '%recurring_subscription%' AND cust.status = 'ACTIVE';"
      )
      Resque.logger.info cust_list.size

      ShopifyAPI::Base.site = base_site
      ShopifyAPI::Base.api_version = '2019-04'

      my_now = Time.now

      cust_list.each do |cust|
        Resque.logger.info cust.inspect
        Resque.logger.info "Shopify id: #{cust.customer_id}"
        api_limiter
        begin
          customer_obj = ShopifyAPI::Customer.find(cust.customer_id.to_i)
        rescue StandardError => e
          Resque.logger.info "#{e.inspect}"
          next
        end
        # convert shopify customer tags in array of strings
        my_tags = customer_obj.tags.split(",")
        my_tags.map! {|x| x.strip}
        Resque.logger.info "tags before: #{customer_obj.tags.inspect}"
        changes_made = false

        my_tags.each do |x|
          if x.include?("recurring_subscription")
            my_tags.delete(x)
            # changes_made = true
          end
        end
        Resque.logger.info "tags now: #{my_tags}"

        # update shopify customer tags locally
        if changes_made
          cust.tags = my_tags.join(",")
          cust.save!
          customer_obj.tags = my_tags.join(",")
          customer_obj.save!
          Resque.logger.info "changes made, tags after: #{customer_obj.tags.inspect}"
        else
          Resque.logger.info "No changes made, recurring_subscription tag not found in: #{customer_obj.tags.inspect}"
        end

        my_current = Time.now
        duration = (my_current - my_now).ceil
        Resque.logger.debug "Been running #{duration} seconds"
      end
    end

    def self.api_limiter
      credit_used = ShopifyAPI.credit_used
      credit_limit = ShopifyAPI.credit_limit
      credit_left = ShopifyAPI.credit_left
      Resque.logger.info "credit used: #{credit_used} credit_left: #{credit_left}"

      if credit_used/credit_limit.to_f > 0.90
        Resque.logger.debug "We have #{credit_left} #{credit_limit} credits left, sleeping 17.."
        sleep 17
      end
    end
  end

end
# binding.pry
   
