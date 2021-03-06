require File.dirname(__FILE__) + '/spec_helper'

class AccountController < ActionController::Base
  authenticated_user
  
  def logout
    process_logout('/') do
      flash[:message] = 'Logged out'
    end
  end
end

describe "Controller#process_logout" do
  controller_name :account
  
  before(:each) do
    @user = mock('User model')
    controller.stub!(:current_user).and_return(@user)
    
    User.stub!(:supports_remember_me?).and_return(false)
    
    cookies[:auth_token] = 'my auth token'
    session[:user] = 1234
  end
  
  def do_get
    with_default_routing { get :logout }
  end
  
  it "should redirect to the provided path" do
    after_get do
      response.should redirect_to('/')
    end
  end
  
  it "should reset the session" do
    before_get do
      controller.should_receive(:reset_session)
    end
  end
  
  it "should remove the auth token cookie" do
    after_get do
      cookies[:auth_token].first.should be_nil
    end
  end
  
  it "should call the block" do
    after_get do
      flash[:message].should_not be_nil
    end
  end
  
  describe "model supports remember me" do
    before(:each) do
      User.stub!(:supports_remember_me?).and_return(true)
    end
    
    it "should forget me" do
      during_get do
        @user.should_receive(:forget_me!)
      end
    end
  end
end
