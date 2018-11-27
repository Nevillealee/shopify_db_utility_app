require 'dotenv'
require 'active_support/core_ext'
require 'sinatra/activerecord'
require 'httparty'
require 'shopify_api'
Dir["/models/*.rb"].each {|file| require file }
require 'pry'
require 'logger'
Dotenv.load

module ResqueHelper
  # TODO(Neville) change STDOUT to 'logs/resque_helper.log' for production
  Resque.logger = Logger.new(STDOUT, progname: 'ResqueHelper', level: 'INFO')

  def get_shopify_customers_full(params)
    Resque.logger.debug "ResqueHelper#get_shopify_customers_full params: #{params}"
    option_value = params['option_value']
    uri = params['connection']
    sleep_shopify = params['sleep_shopify']
    shopify_header = params['shopify_base']
    myuri = URI.parse(uri)
    my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)

    if option_value == "full_pull"
      #delete all shopify_customer_tables
      Resque.logger.warn "Deleting shopify_customers table"
      shopify_customers_delete = "delete from shopify_customers"
      shopify_customers_reset = "ALTER SEQUENCE shopify_customers_id_seq RESTART WITH 1"
      my_conn.exec(shopify_customers_delete)
      my_conn.exec(shopify_customers_reset)
      Resque.logger.info "Deleted all shopify_customer table information and reset the id sequence"
      my_conn.close
      num_customers = background_count_shopify_customers(shopify_header)
      Resque.logger.info "We have #{num_customers} customers to download"
      background_load_full_shopify_customers(sleep_shopify, num_customers, shopify_header, uri)

    elsif option_value == "yesterday"
      Resque.logger.info "downloading only yesterday's shopify customers"
      my_today = Date.today
      Resque.logger.debug "Today is #{my_today}"
      my_yesterday = my_today - 1
      num_updated_cust = background_count_yesterday_shopify_customers(my_yesterday, shopify_header)
      Resque.logger.info "We have #{num_updated_cust} shopify customers who are new or have been updated since yesterday"
      background_load_modified_shopify_customers(sleep_shopify, num_updated_cust, shopify_header, uri)

    else
      Resque.logger.error "Sorry can't understand what the option_value #{option_value} means"
    end
  end

  def background_count_shopify_customers(shopify_header)
    #GET /customers/count
    ShopifyAPI::Base.site = shopify_header
    my_count = ShopifyAPI::Customer.count
    Resque.logger.debug "ResqueHelper#background_count_shopify_customers #{my_count}"
    return my_count
  end

  def background_count_yesterday_shopify_customers(my_yesterday, shopify_header)
    updated_at_min = my_yesterday.strftime("%Y-%m-%d")
    ShopifyAPI::Base.site = shopify_header
    my_count = ShopifyAPI::Customer.count({updated_at_min: updated_at_min})
    Resque.logger.debug "ResqueHelper#background_count_yesterday_shopify_customers count: #{my_count}"
    return my_count
  end

  def background_load_full_shopify_customers(sleep_shopify, num_customers, shopify_header, uri)
    Resque.logger.info "starting download"
    myuri = URI.parse(uri)
    my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
    my_insert = "insert into shopify_customers (accepts_marketing, addresses, created_at, default_address, email, first_name, customer_id, last_name, last_order_id, last_order_name, metafield, multipass_identifier, note, orders_count, phone, state, tags, tax_exempt, total_spent, updated_at, verified_email) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)"

    my_conn.prepare('statement1', "#{my_insert}")

    start = Time.now
    page_size = 250
    num_pages = (num_customers/page_size.to_f).ceil
    1.upto(num_pages) do |page|
      customers = HTTParty.get(shopify_header + "/customers.json?limit=250&page=#{page}")

      my_customers = customers.parsed_response['customers']
      my_customers.each do |mycust|
        customer_id = mycust['id']
        accepts_marketing = mycust['accepts_marketing']
        addresses = mycust['addresses']
        created_at = mycust['created_at']
        default_address = mycust['default_address']
        email = mycust['email']
        first_name = mycust['first_name']
        last_name = mycust['last_name']
        last_order_id = mycust['last_order_id']
        last_order_name = mycust['last_order_name']
        metafield = mycust['metafield']
        multipass_identifier = mycust['multipass_identifier']
        note = mycust['note']
        orders_count = mycust['orders_count']
        phone = mycust['phone']
        state = mycust['state']
        tags = mycust['tags']
        tax_exempt = mycust['tax_exempt']
        total_spent = mycust['total_spent']
        updated_at = mycust['updated_at']
        verified_email = mycust['verified_email']
        my_conn.exec_prepared('statement1', [accepts_marketing, addresses.to_json, created_at, default_address.to_json, email, first_name, customer_id, last_name, last_order_id, last_order_name, metafield.to_json, multipass_identifier, note, orders_count, phone, state, tags, tax_exempt, total_spent, updated_at, verified_email])

      end
      Resque.logger.info "Done with page #{page}/#{num_pages}"
      current = Time.now
      duration = (current - start).ceil
      Resque.logger.info "Running #{duration} seconds"
      Resque.logger.info "Sleeping #{sleep_shopify}"
      sleep sleep_shopify.to_i
    end
    Resque.logger.info "All done"
    my_conn.close
  end

  def background_load_modified_shopify_customers(sleep_shopify, num_customers, shopify_header, uri)
    Resque.logger.info "Doing partial download new or modified customers since yesterday"
    myuri = URI.parse(uri)
    my_conn =  PG.connect(myuri.hostname, myuri.port, nil, nil, myuri.path[1..-1], myuri.user, myuri.password)
    my_insert = "insert into shopify_customers (accepts_marketing, addresses, created_at, default_address, email, first_name, customer_id, last_name, last_order_id, last_order_name, metafield, multipass_identifier, note, orders_count, phone, state, tags, tax_exempt, total_spent, updated_at, verified_email) values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)"
    my_conn.prepare('statement1', "#{my_insert}")

    #Delete all customers from day before yesterday
    my_temp_update = "update shopify_customers set accepts_marketing = $1, addresses = $2, created_at = $3, default_address = $4, email = $5, first_name = $6, customer_id = $7, last_name = $8, last_order_id = $9, last_order_name = $10, metafield = $11, multipass_identifier = $12, note = $13, orders_count = $14, phone = $15, state = $16, tags = $17, tax_exempt = $18, total_spent = $19, updated_at = $20, verified_email = $21  where customer_id = $7"
    my_conn.prepare('statement2', "#{my_temp_update}")


    start = Time.now
    page_size = 250
    num_pages = (num_customers/page_size.to_f).ceil
    1.upto(num_pages) do |page|
      customers = HTTParty.get(shopify_header + "/customers.json?limit=250&page=#{page}")
      my_customers = customers.parsed_response['customers']
      my_customers.each do |mycust|
        customer_id = mycust['id']
        accepts_marketing = mycust['accepts_marketing']
        addresses = mycust['addresses'].to_json
        created_at = mycust['created_at']
        default_address = mycust['default_address'].to_json
        email = mycust['email']
        first_name = mycust['first_name']
        last_name = mycust['last_name']
        last_order_id = mycust['last_order_id']
        last_order_name = mycust['last_order_name']
        metafield = mycust['metafield'].to_json
        multipass_identifier = mycust['multipass_identifier']
        note = mycust['note']
        orders_count = mycust['orders_count']
        phone = mycust['phone']
        state = mycust['state']
        tags = mycust['tags']
        tax_exempt = mycust['tax_exempt']
        total_spent = mycust['total_spent']
        updated_at = mycust['updated_at']
        verified_email = mycust['verified_email']
        my_ind_select = "select * from shopify_customers where customer_id = \'#{customer_id}\'"
        temp_result = my_conn.exec(my_ind_select)
        if !temp_result.num_tuples.zero?
          Resque.logger.info "Found existing record"
          temp_result.each do |myrow|
            customer_id = myrow['customer_id']
            Resque.logger.info "Customer ID #{customer_id}"
            indy_result = my_conn.exec_prepared('statement2', [accepts_marketing, addresses, created_at, default_address, email, first_name, customer_id, last_name, last_order_id, last_order_name, metafield, multipass_identifier, note, orders_count, phone, state, tags, tax_exempt, total_spent, updated_at, verified_email])
            Resque.logger.debug indy_result.inspect
          end
        else
          Resque.logger.info "Need to insert a new record"
          Resque.logger.info "inserting #{customer_id}, #{first_name} #{last_name}"
          ins_result = my_conn.exec_prepared('statement1', [accepts_marketing, addresses, created_at, default_address, email, first_name, customer_id, last_name, last_order_id, last_order_name, metafield, multipass_identifier, note, orders_count, phone, state, tags, tax_exempt, total_spent, updated_at, verified_email])
          Resque.logger.debug ins_result.inspect
          sleep 4
        end

      end
      Resque.logger.info "Done with page #{page}/#{num_pages}"
      current = Time.now
      duration = (current - start).ceil
      Resque.logger.info "Running #{duration} seconds"
      Resque.logger.info "Sleeping #{sleep_shopify}"
      sleep sleep_shopify.to_i
    end
    Resque.logger.info "All done"
    my_conn.close

  end
end
