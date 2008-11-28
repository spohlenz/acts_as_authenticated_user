require File.dirname(__FILE__) + '/spec_helper'

class AccountController < ActionController::Base
  authenticated_user
  
  def logout
    process_logout '/' do
      flash[:message] = 'Logged out'
    end
  end
end

describe "Controller#process_logout" do
  controller_name :account
  
  def do_get
    session[:user] = 1234
    with_default_routing { get :logout }
  end
  
  it "should redirect to the provided path" do
    after_get do
      response.should redirect_to('/')
    end
  end
  
  it "should clear the current user" do
    before_get do
      controller.should_receive(:current_user=).with(nil)
    end
  end
  
  it "should call the block" do
    after_get do
      flash[:message].should_not be_nil
    end
  end
end
