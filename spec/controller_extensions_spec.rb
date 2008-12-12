require File.dirname(__FILE__) + '/spec_helper'

class User; end

class TestController < ActionController::Base
  authenticated_user
  
  def test_action
  end
end

describe "Controller#current_user" do
  controller_name :test
  
  before(:each) do
    @user = mock('User instance', :id => 1234)
    User.stub!(:find_by_id).and_return(@user)
    
    TestController.send(:public, :current_user, :current_user=)
  end
  
  def do_get
    with_default_routing { get :test_action }
  end
  
  it "should be settable" do
    controller.current_user = @user
    controller.current_user.should == @user
    session[:user].should == 1234
  end
  
  it "should be a helper method" do
    controller.class.helpers.should respond_to(:current_user)
  end
  
  describe "no current user in session, cookie or http basic auth" do
    before(:each) { session[:user] = nil }
    
    it "should be nil" do
      after_get do
        controller.current_user.should be_nil
      end
    end
  end
  
  describe "login from session" do
    before(:each) do
      User.stub!(:find_by_id).and_return(@user)
      session[:user] = 1234
    end
    
    it "should find the user" do
      after_get do
        controller.current_user.should == @user
      end
    end
  end
  
  describe "login from cookie" do
    describe "auth token is valid" do
      before(:each) do
        User.stub!(:find_by_remember_token).and_return(@user)
        @user.stub!(:remember_token_expired?).and_return(false)
        cookies[:auth_token] = 'valid token'
      end
      
      it "should find the user" do
        after_get do
          controller.current_user.should == @user
        end
      end
      
      it "should set the session" do
        after_get do
          session[:user].should == 1234
        end
      end
    end
    
    describe "auth token is invalid" do
      before(:each) do
        User.stub!(:find_by_remember_token).and_return(nil)
        cookies[:auth_token] = 'invalid token'
      end
      
      it "should be nil" do
        after_get do
          controller.current_user.should be_nil
        end
      end
    end
    
    describe "auth token is expired" do
      before(:each) do
        User.stub!(:find_by_remember_token).and_return(@user)
        @user.stub!(:remember_token_expired?).and_return(true)
        cookies[:auth_token] = 'valid token'
      end
      
      it "should be nil" do
        after_get do
          controller.current_user.should be_nil
        end
      end
    end
  end
  
  describe "login using http basic auth" do
    
  end
end


describe "Controller#logged_in?" do
  controller_name :test
  
  before(:each) do
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
    controller.class.helpers.should respond_to(:logged_in?)
  end
end


describe "Controller#authenticated_user" do
  controller_name :test
  
  before(:each) do
    TestController.send(:authenticated_user)
  end
  
  ['user_model', 'current_user', 'current_user=', 'logged_in?'].each do |method|
    it "should define protected method #{method}" do
      controller.protected_methods.should include(method)
    end
  end
  
  it "should set user model to User" do
    controller.send(:user_model).should == User
  end
end


describe "Controller#require_login" do
  controller_name :test
  
  before(:each) do
    TestController.send(:require_login, :login_path => '/login')
  end
  
  it "should append the check_login before_filter" do
    TestController.before_filters.should include(:check_login)
  end
  
  ['user_conditions', 'check_login', 'login_action'].each do |method|
    it "should define protected method #{method}" do
      controller.protected_methods.should include(method)
    end
  end
end


describe "Controller#skip_login" do
  controller_name :test
  
  before(:each) do
    TestController.send(:require_login, :login_path => '/login')
    TestController.send(:skip_login)
  end
  
  it "should remove the check_login before_filter" do
    TestController.before_filter.should_not include(:check_login)
  end
end


describe "Controller#check_login" do
  controller_name :test
  
  before(:each) do
    TestController.send(:require_login, :login_path => '/login')
  end
  
  def do_get
    with_default_routing { get :test_action }
  end
  
  describe 'no current user' do
    before(:each) do
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

  describe 'logged in user' do
    before(:each) do
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
