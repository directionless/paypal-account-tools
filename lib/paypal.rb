# some paypal routines

require "webrat"
require 'webrat/adapters/mechanize'
include Webrat::Methods
include Webrat::Matchers
require "webrat_bugs.rb"
require 'pp'

Webrat.configure do |config|
  config.mode = :mechanize
end

class PayPal

  LOGIN_URL='https://www.paypal.com/us/cgi-bin/webscr?cmd=_login-run'
  MULTIUSER_URL="https://www.paypal.com/us/cgi-bin/webscr?cmd=_profile-logins"

  def initialize(user,password)
    @users = [];
    login(user,password)
    get_users()
  end


  def multiuser_add(options)
    visit MULTIUSER_URL
    click_button "Add User"
    fill_in "name", :with => options[:name]
    fill_in "login1", :with => options[:username]
    fill_in "login2", :with => options[:username]
    fill_in "password1", :with => options[:password]
    fill_in "password2", :with => options[:password]
    options[:privileges].each { |priv| check priv }
    click_button "Save"
    get_users()
  end

  def multiuser_delete(options)
    users=filter_users(options[:filter])
    puts "This is going to delete:\n"
    puts users.map { |u| nice_user_display(u) }
    get_user_confirmation()

    users.each do |u|
      puts "deleting #{nice_user_display(u)}"
      visit MULTIUSER_URL
      choose u[:id]
      click_button "Remove"
      click_button "Yes"
      File.open("/tmp/paypal.html", "w") { |f| f.write response_body }
    end
    get_users()
  end


  def list_users(options={})
    users=filter_users(options[:filter])
    pp(users)
  end

  private

  def get_user_confirmation()
    puts ""
    puts "Are you sure? (type \"yes\" to continue) "
    response = gets.chomp
    exit unless response == "yes"
  end

  def nice_user_display(u)
    u[:name] + "[" + u[:username] + "]" 
  end

  def filter_users(filter="")
    @users.select { |u| u[:username] =~ /#{filter}/i }
  end

  def login(user, password)
    visit LOGIN_URL
    fill_in /email/, :with => user
    fill_in /password/, :with => password
    click_button "Log In"
    sleep 0.5
  end

  def get_users(options={})
    @users=[]
    visit MULTIUSER_URL
    doc=Webrat::XML.document(response_body)
    user_rows=doc.xpath('//tbody//tr')
    user_rows.map do |row| 
      @users << {
        :id       => row.xpath('.//td').first.children.first.attribute("id").text,
        :username => row.xpath('.//td').last.text,
        :name     => row.xpath('.//strong').text,
      }
    end
  end
  


end


