require File.dirname(__FILE__) + '/spec_helper'

class TestController < ActionController::Base
  #authenticated_user :model => User
  
  def test_action
  end
end

class User; end

describe "Controller#current_user" do
  controller_name :test
  
  setup do
    TestController.send(:public, :current_user, :current_user=)
    @user = mock('User instance')
    User.stub!(:find_by_id).and_return(@user)
    controller.stub!(:user_model).and_return(User)
  end
  
  it "should be settable" do
    @user = mock('User model', :id => 1234)
    controller.current_user = @user
    
    controller.current_user.should == @user
    session[:user].should == 1234
  end
  
  it "should be nullable" do
    controller.current_user = nil
    controller.current_user.should be_nil
  end
  
  it "should be a helper method" do
    class View; end
    View.send(:include, controller.master_helper_module)
    View.new.should respond_to(:current_user)
  end
  
  context "user id not in session" do
    setup { session[:user] = nil }
    
    it "should be nil if session not set" do
      controller.current_user.should be_nil
    end
  end
  
  context "user id set in session" do
    setup { session[:user] = 1234 }
    
    it "should find the user if session id set" do
      User.should_receive(:find_by_id).with(1234).and_return(@user)
      controller.current_user.should == @user
    end
  end
end


describe "Controller#logged_in?" do
  controller_name :test
  
  setup do
    TestController.send(:public, :logged_in?)
  end
  
  it "should return true if user is logged in" do
    controller.stub!(:current_user).and_return(mock('User model'))
    controller.logged_in?.should be_true
  end
  
  it "should return false if user is not logged in" do
    controller.stub!(:current_user).and_return(nil)
    controller.logged_in?.should be_false
  end
  
  it "should be a helper method" do
    class View; end
    View.send(:include, controller.master_helper_module)
    View.new.should respond_to(:logged_in?)
  end
end


describe "Controller#require_login" do
  controller_name :test
  
  setup do
    TestController.send(:require_login, :login_path => '/login')
  end
  
  it "should append the check_login before_filter" do
    TestController.find_filter(:check_login).should_not be_nil
  end
  
  ['user_model', 'user_conditions', 'login_message', 'login_action'].each do |method|
    it "should define protected method #{method}" do
      controller.protected_methods.should include(method)
    end
  end
end


describe "Controller#skip_login" do
  controller_name :test
  
  setup do
    TestController.send(:require_login, :login_path => '/login')
    TestController.send(:skip_login)
  end
  
  it "should remove the check_login before_filter" do
    TestController.find_filter(:check_login).should be_nil
  end
end


describe "Controller#check_login" do
  controller_name :test
  
  setup do
    TestController.send(:require_login, :login_path => '/login')
  end
  
  def do_get
    get :test_action
  end
  
  context 'no current user' do
    setup do
      controller.stub!(:current_user).and_return(nil)
    end
    
    it "should set an error message" do
      after_get do
        flash[:error].should_not be_nil
      end
    end
  
    it "should redirect to login action" do
      after_get do
        response.should redirect_to('/login')
      end
    end
  
    it "should save the current request path" do
      after_get do
        session[:previous_location].should == '/test/test_action'
      end
    end
  end

  context 'logged in user' do
    setup do
      controller.stub!(:current_user).and_return(mock('User model'))
    end
    
    it "should not set an error" do
      after_get do
        flash[:error].should be_nil
      end
    end
  
    it "should not redirect" do
      response.should_not be_redirect
    end
  end
end
