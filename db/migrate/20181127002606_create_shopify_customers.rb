class CreateShopifyCustomers < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_customers do |t|
      t.boolean :accepts_marketing
      t.jsonb :addresses
      t.datetime :created_at
      t.jsonb :default_address
      t.string :email
      t.string :first_name
      t.string :customer_id
      t.string :last_name
      t.string :last_order_id
      t.string :last_order_name
      t.jsonb :metafield
      t.string :multipass_identifier
      t.string :note
      t.integer :orders_count
      t.string :phone
      t.string :state
      t.string :tags
      t.boolean :tax_exempt
      t.string :total_spent
      t.datetime :updated_at
      t.boolean :verified_email
    end
  end
end
