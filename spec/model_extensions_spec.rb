require File.dirname(__FILE__) + '/spec_helper'

class DefaultUser < ActiveRecord::Base
  acts_as_authenticated_user
end

describe 'A model which calls acts_as_authenticated_user' do
  setup do
    @user = DefaultUser.new(:login => 'test')
  end
  
  it "should have a password accessor" do
    @user.should respond_to(:password)
    @user.should respond_to(:password=)
  end
  
  it "should require a login" do
    @user.should validate_presence_of(:login)
  end
  
  it "should require a unique login" do
    @user.should validate_uniqueness_of(:login)
  end
  
  it "should disallow mass-assignment of hashed_password and salt" do
    @user.should_not allow_mass_assignment_of(:hashed_password)
    @user.should_not allow_mass_assignment_of(:salt)
  end
  
  it "should be able to encrypt password and salt using SHA1" do
    User.encrypt('12345678abc', 'abcdefg').should == 'cb366af975f0b948eda8d25cdc471ce3b090c493'
    User.encrypt('87654321def', 'hello').should == '0d46fe8292c2bfbe471384468c7506a948eb5282'
  end
  
  it "should validate presence of password and confirmation when password required" do
    @user.stub!(:password_required?).and_return(true)
    @user.should validate_presence_of(:password)
    @user.should validate_presence_of(:password_confirmation)
  end
  
  it "should not validate presence of password and confirmation when password not required" do
    @user.stub!(:password_required?).and_return(false)
    @user.should_not validate_presence_of(:password)
    @user.should_not validate_presence_of(:password_confirmation)
  end
  
  it "should require a password if hashed_password is blank" do
    @user.send(:password_required?).should == true
  end
  
  it "should not require a password if hashed_password already set" do
    @user.hashed_password = 'some hash'
    @user.send(:password_required?).should == false
  end
  
  it "should require a password if password is not blank, even if hashed_password is set" do
    @user.hashed_password = 'some old hash'
    @user.password = 'new pass'
    @user.send(:password_required?).should == true
  end
end


describe "A user encrypting their password" do
  setup do
    @user = DefaultUser.new(:login => 'test', :password => 'mypassword')
    Time.stub!(:now).and_return('Fri May 16 17:00:55 -0700 2008')
  end
  
  it "should encrypt password when saving" do
    @user.should_receive(:encrypt_password)
    @user.save(false)
  end
  
  it "should set a salt when encrypting the password and salt was previously blank" do
    @user.should_receive(:salt=).with('628e6d655863f6600749f58ae3135d0de34dde21')
    @user.send(:encrypt_password)
  end
  
  it "should not set a salt if already set" do
    @user.stub!(:salt).and_return('salty')
    @user.should_not_receive(:salt=)
    @user.send(:encrypt_password)
  end
  
  it "should set the hashed password" do
    @user.stub!(:salt).and_return('salty')
    DefaultUser.should_receive(:encrypt).with('mypassword', 'salty').and_return('password hash')
    @user.should_receive(:hashed_password=).with('password hash')
    @user.send(:encrypt_password)
  end
end


describe "Authenticating user" do
  setup do
    @user = DefaultUser.create(:login => 'login', :password => 'password', :password_confirmation => 'password')
  end
  
  it "should succeed with correct login and password" do
    DefaultUser.authenticate('login', 'password').should == @user
  end
  
  it "should fail with incorrect login and password" do
    DefaultUser.authenticate('login', 'incorrect').should be_nil
  end
end


# describe "A model which calls acts_as_authenticated_user with an alternate identifier" do
#   class EmailUser < ActiveRecord::Base
#     acts_as_authenticated_user :identifier => :email
#   end
#   
#   setup do
#     @user = EmailUser.new(:email => 'test@test.com')
#   end
# end
