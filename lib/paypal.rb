# some paypal routines

require "webrat"
require 'webrat/adapters/mechanize'
require "webrat/selenium"

include Webrat::Methods
include Webrat::Matchers
#include Webrat::Selenium::Methods
#include Webrat::Selenium::Matchers

require "webrat_bugs.rb"
require 'pp'

Webrat.configure do |config|
  config.mode = :mechanize
  #config.mode = :selenium
  config.application_framework = :external
end

class PayPal

  LOGIN_URL='https://www.paypal.com/us/cgi-bin/webscr?cmd=_login-run'
  LOGOUT_URL='https://www.paypal.com/us/cgi-bin/webscr?cmd=_logout'
  MULTIUSER_URL="https://www.paypal.com/us/cgi-bin/webscr?cmd=_profile-logins"

  def initialize(user,password)
    @users = [];
    login(user,password)
    get_users()
  end


  def multiuser_add(options)
    begin
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
    rescue Webrat::NotFoundError
      dfile="/tmp/paypal.html"
      File.open(dfile, "w") { |f| f.write response_body }      
      puts "Something fishy happened in multiuser_add"
      puts "So I wrote your file to #{dfile}"
      exit 1
    end
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
    end
    get_users()
  end

  def multiuser_set_privs(options)
    users=filter_users(options[:filter])
    users.each do |u|
      visit MULTIUSER_URL
      choose u[:id]
      click_button "Edit"

      # This is kinda gross, but I don't see a simpler way to uncheck all.
      doc=Webrat::XML.document(response_body)
      checkboxes = doc.xpath("//input").map { |d| d.attribute("name").text if d.attribute("type").text == "checkbox" }.select { |x| x != nil }
      checkboxes.each { |checkbox| uncheck checkbox }

      # Now check the desired ones
      options[:privileges].each { |priv| check priv }
      click_button "Save"
      # some permissions have a confirmation screen. Just blindly take it
      # just always try hitting accept
      begin
        click_button "Accept"
      rescue Webrat::NotFoundError
      end
    end
    get_users()
  end

  # I don't really understand why, but I'm having trouble trying to
  # set this permission with the others. So, I've created a different
  # function for it. Stupid special casing.
  #
  # This doesn't work. I'm guessing it's weird js stuff I haven't figured out.
  def multiuser_enable_customer_support(options)
    users=filter_users(options[:filter])
    users.each do |u|
      visit MULTIUSER_URL
      choose u[:id]
      click_button "Edit"
      check "priv_permission_contact"
      File.open("/tmp/paypal1.html", "w") { |f| f.write response_body }
      click_button "Save"
      File.open("/tmp/paypal2.html", "w") { |f| f.write response_body }
      sleep 0.5
      click_button "Accept"
      File.open("/tmp/paypal3.html", "w") { |f| f.write response_body }
    end
  end


  def list_users(options={})
    users=filter_users(options[:filter])
    pp(users)
  end

  def logout()
    visit LOGOUT_URL
  end


  private

  # implement this special method so we can catch errors.
  alias :old_click_button :click_button
  def click_button(arg)
    begin
      old_click_button arg
    rescue Webrat::NotFoundError
      dfile="/tmp/paypal.html"
      File.open(dfile, "w") { |f| f.write response_body }      
      puts "You asked me to click #{arg}, but I couldn't find it"
      puts "So I wrote your file to #{dfile}"
      exit 1
    end
  end

#  alias :old_fill_in :fill_in
#  def fill_in(arg1, arg2)
#    begin
#      old_fill_in arg1 arg2
#    rescue Webrat::NotFoundError
#      dfile="/tmp/paypal.html"
#      File.open(dfile, "w") { |f| f.write response_body }      
#      puts "You asked me to fill_in #{arg}, but I couldn't find it"
#      puts "So I wrote your file to #{dfile}"
#      exit 1
#    end
#  end

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


