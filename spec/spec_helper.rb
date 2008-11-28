begin
  require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
rescue LoadError
  puts "You need to install rspec in your base app"
  exit
end

plugin_spec_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

databases = YAML::load(IO.read(plugin_spec_dir + "/db/database.yml"))
ActiveRecord::Base.establish_connection(databases[ENV["DB"] || "sqlite3"])
load(File.join(plugin_spec_dir, "db", "schema.rb"))

Spec::Runner.configure do |config|
  [:get, :post, :put, :delete, :render].each do |action|
    eval %Q{
      def before_#{action}
        yield
        do_#{action}
      end
      alias during_#{action} before_#{action}
      def after_#{action}
        do_#{action}
        yield
      end
    }
  end
  
  def it_should_have_attr_accessor(sym)
    it "should have accessor '#{sym}'" do
      instance.should respond_to(sym)
      instance.should respond_to("#{sym}=")
    end
  end
  
  def with_default_routing
    with_routing do |set|
      set.draw do |map|
        map.connect ':controller/:action/:id'
        yield
      end
    end
  end
end
