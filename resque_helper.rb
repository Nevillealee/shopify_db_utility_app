require 'dotenv'
require 'active_support/core_ext'
require 'sinatra/activerecord'
require 'httparty'
Dir["/models/*.rb"].each {|file| require file }
require 'pry'

Dotenv.load

module ResqueHelper
end
