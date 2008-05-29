require File.dirname(__FILE__) + '/../../../../spec/spec_helper'

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
end
