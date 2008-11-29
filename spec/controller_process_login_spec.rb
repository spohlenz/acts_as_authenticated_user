require File.dirname(__FILE__) + '/spec_helper'

class AccountController < ActionController::Base
  authenticated_user
  
  def login
    process_login(params[:user], '/foo/bar') do |login|
      login.success { login_succeeded! }
      login.failure { login_failed! }
    end
  end
end

describe "Controller#process_login" do
  controller_name :account
  
  describe 'handling GET' do
    def do_get
      with_default_routing { get :login }
    end
  
    it "should be successful" do
      after_get do
        response.should be_success
      end
    end
  
    it "should not process blocks" do
      before_get do
        controller.should_not_receive(:login_succeeded!)
        controller.should_not_receive(:login_failed!)
      end
    end
  end
  
  describe "handling POST" do
    context "valid authentication" do
      before(:each) do
        @user = mock('User model', :id => 1234)
        User.stub!(:authenticate).and_return(@user)
        controller.stub!(:login_succeeded!)
      end
  
      def do_post
        with_default_routing do
          post :login, :user => { :login => 'login', :password => 'password' }
        end
      end
  
      it "should authenticate the user" do
        before_post do
          User.should_receive(:authenticate).with('login', 'password').and_return(@user)
        end
      end
  
      it "should redirect to success path" do
        after_post do
          response.should redirect_to('/foo/bar')
        end
      end
  
      it "should redirect to previous location if set" do
        session[:previous_location] = '/last/location'
        after_post do
          response.should redirect_to('/last/location')
        end
      end
  
      it "should set the current user" do
        before_post do
          controller.should_receive(:current_user=).with(@user)
        end
      end
  
      it "should process success block" do
        before_post do
          controller.should_receive(:login_succeeded!)
        end
      end
  
      it "should not process failure block" do
        before_post do
          controller.should_not_receive(:login_failed!)
        end
      end
      
      describe "with 'remember me' set" do
        def do_post
          with_default_routing do
            post :login, :user => { :login => 'login', :password => 'password', :remember_me => '1' }
          end
        end
        
        before(:each) do
          User.stub!(:supports_remember_me?).and_return(true)
        end
        
        it "should remember me" do
          before_post do
            @user.should_receive(:remember_me!)
          end
        end
      end
    end


    context "invalid authentication" do
      before(:each) do
        User.stub!(:authenticate).and_return(nil)
        controller.stub!(:login_failed!)
      end
  
      def do_post
        with_default_routing do
          post :login, :user => { :login => 'login', :password => 'invalid' }
        end
      end
  
      it "should attempt to authenticate the user" do
        before_post do
          User.should_receive(:authenticate).with('login', 'invalid').and_return(nil)
        end
      end
  
      it "should be successful" do
        after_post do
          response.should be_success
        end
      end
  
      it "should not process success block" do
        before_post do
          controller.should_not_receive(:login_succeeded!)
        end
      end
  
      it "should process failure block" do
        before_post do
          controller.should_receive(:login_failed!)
        end
      end
    end
  end
end
