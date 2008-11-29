require File.dirname(__FILE__) + '/spec_helper'

class DefaultUser < ActiveRecord::Base
  acts_as_authenticated_user
end

describe 'A model which calls acts_as_authenticated_user' do
  def instance
    @user
  end
  
  def valid_attributes
    {
      :login => 'test',
      :password => 'password',
      :password_confirmation => 'password'
    }
  end
  
  before(:each) do
    @user = DefaultUser.new
  end
  
  it_should_have_attr_accessor :password
  
  it_should_validate_presence_of :login
  it_should_validate_uniqueness_of :login
  
  it_should_not_mass_assign :hashed_password
  it_should_not_mass_assign :salt
  
  it "identifier_column should default to :login" do
    DefaultUser.identifier_column.should == :login
  end
  
  it "should be able to encrypt password and salt using SHA1" do
    DefaultUser.encrypt('12345678abc', 'abcdefg').should == 'cb366af975f0b948eda8d25cdc471ce3b090c493'
    DefaultUser.encrypt('87654321def', 'hello').should == '0d46fe8292c2bfbe471384468c7506a948eb5282'
  end
  
  describe "when password is required" do
    before(:each) do
      @user.stub!(:password_required?).and_return(true)
    end
    
    it_should_validate_presence_of :password
    it_should_validate_presence_of :password_confirmation
  end
  
  describe "when password not required" do
    before(:each) do
      @user.stub!(:password_required?).and_return(false)
    end
    
    it_should_not_validate_presence_of :password
    it_should_not_validate_presence_of :password_confirmation
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
  before(:each) do
    @user = DefaultUser.new(:login => 'test', :password => 'mypassword')
    Time.stub!(:now).and_return(Time.parse('Fri May 16 17:00:55 -0700 2008'))
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
  before(:each) do
    @user = DefaultUser.create(:login => 'login', :password => 'password', :password_confirmation => 'password')
  end
  
  it "should succeed with correct login and password" do
    DefaultUser.authenticate('login', 'password').should == @user
  end
  
  it "should fail with incorrect login and password" do
    DefaultUser.authenticate('login', 'incorrect').should be_nil
  end
end


describe "A model which calls acts_as_authenticated_user with an alternate identifier" do
  class EmailUser < ActiveRecord::Base
    acts_as_authenticated_user :identifier => :email
  end
  
  before(:each) do
    @user = EmailUser.new
  end
  
  def instance
    @user
  end
  
  def valid_attributes
    {
      :email => 'test@example.com',
      :password => 'password',
      :password_confirmation => 'password'
    }
  end
  
  it_should_validate_presence_of :email
  it_should_validate_uniqueness_of :email
  
  it "identifier_column should be :email" do
    EmailUser.identifier_column.should == :email
  end
  
  it "should authenticate with email and password" do
    @user = EmailUser.create(:email => 'foo@foo.com', :password => 'pass', :password_confirmation => 'pass')
    EmailUser.authenticate('foo@foo.com', 'pass').should == @user
  end
end


describe "A model which calls acts_as_authenticated_user with validations disabled" do
  class NoValidationUser < ActiveRecord::Base
    acts_as_authenticated_user :validate => false
  end
  
  it "should be valid with no attributes" do
    @user = NoValidationUser.new
    @user.should be_valid
  end
end


describe "A model which calls acts_as_authenticated_user with remember_token fields" do
  class MemorableUser < ActiveRecord::Base
    acts_as_authenticated_user
  end
  
  before(:each) do
    @user = MemorableUser.new
    Time.freeze!
  end
  
  it "should remember me for 30 days" do
    @user.should_receive(:save).with(false)
    @user.remember_me!
    
    @user.remember_token.should_not be_blank
    @user.remember_token_expires_at.should == 30.days.from_now
  end
  
  it "should allow overriding of remember me duration" do
    old_duration = MemorableUser.remember_me_duration
    
    MemorableUser.remember_me_duration = 2.weeks
    @user.remember_me!
    @user.remember_token_expires_at.should == 2.weeks.from_now
    
    MemorableUser.remember_me_duration = old_duration
  end
  
  it "should forget me" do
    @user.remember_token = 'mytoken'
    @user.remember_token_expires_at = 2.weeks.from_now
    
    @user.should_receive(:save).with(false)
    @user.forget_me!
    
    @user.remember_token.should be_nil
    @user.remember_token_expires_at.should be_nil
  end
end
