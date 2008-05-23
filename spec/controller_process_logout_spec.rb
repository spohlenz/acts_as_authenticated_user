require File.dirname(__FILE__) + '/spec_helper'

class AccountController < ActionController::Base
  def logout
    process_logout '/'
  end
end

describe "Controller#process_logout" do
  controller_name :account
  
  def do_get
    session[:user] = 1234
    get :logout
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
end
