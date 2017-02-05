#!/usr/bin/env ruby

# 2011-01 seph@directionless.org

# since paypal doesn't have any way to manage users across several
# accounts, I thought I'd see about scripting some of this. It's ugly,
# but it's got to be easier than creating 70 accounts by hand.

# Grab my various libs
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require "webrat"
require 'webrat/adapters/mechanize'
include Webrat::Methods
include Webrat::Matchers
require "webrat_bugs.rb"

require "paypal"

require 'pp'

Webrat.configure do |config|
  config.mode = :mechanize
end



# First, let's login
paypal_login(ENV["PAYPAL_USER"], ENV["PAYPAL_PASSWORD"])




# create some users
paypal_multiuser_add({ :name     => "A User",
                       :username => "auser",
                       :password => "password",
                       :privileges => ["priv_view_balance"],
                     })


File.open("/tmp/paypal.html", "w") { |f| f.write response_body }

paypal_list_users()
