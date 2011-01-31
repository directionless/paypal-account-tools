#!/usr/bin/env ruby

# 2011-01 seph@directionless.org

# Grab my various libs
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))


require "paypal"

p=PayPal.new(ENV["PAYPAL_USER"], ENV["PAYPAL_PASSWORD"])

p.list_users()


p.multiuser_add({ :name     => "Example User",
                  :username => "example" + (0...7).map{ ('a'..'z').to_a[rand(26)] }.join,
                  :password => (0...10).map{ ('a'..'z').to_a[rand(26)] }.join,
                  :privileges => ["priv_view_balance"],
                })

p.list_users()

p.multiuser_delete({:filter=>"example"})

p.list_users()
