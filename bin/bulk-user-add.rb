#!/usr/bin/env ruby
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "rubygems"
require 'yaml'
require 'pp'
require "paypal"


ACCOUNT_PREFIX="EX"
MAX_CHARACTERS=16
# priv_permission_contact
PRIVILEGES=["priv_view_balance", "priv_view_profile", "priv_edit_profile", "priv_api_access"]

users = YAML.load_file("paypal-users.yaml")
accounts = YAML.load_file("paypal.yaml")

accounts.each do |account|
  puts "Now working on #{account[:name]}"
  p=PayPal.new(account[:email], account[:password])
  users.each do |user|
    username = "#{ACCOUNT_PREFIX}#{user[:user]}#{account[:abbr]}"
    puts "ERROR: #{username} has #{username.length} characters" if username.length > MAX_CHARACTERS

    p.multiuser_add({ :name     => user[:name],
                      :username => username,
                      :password => user[:pass],
                      :privileges => PRIVILEGES,
                    })

    # I wish this worked, but it doesn't
    p.multiuser_enable_customer_support({ :filter   => username })

  end

#  p.list_users()
end
