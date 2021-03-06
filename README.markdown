acts\_as\_authenticated\_user
==========================

*acts\_as\_authenticated\_user* is a Rails user authentication plugin which is in many respects comparable to the similarly named acts\_as\_authenticated. Like acts\_as\_authenticated, it uses SHA1 hashes and salted passwords.

It differs from acts\_as\_authenticated in that it does not use generators (which leads to a User model cluttered with authentication logic). Instead, authentication logic is included automatically by calling an acts\_ method (acts\_as\_authenticated despite its name, does not use any acts\_ methods) within your user model.

Similarly, abstractions are provided for controllers to keep as much authentication logic 'under the hood'. See below for examples.


Installation
------------

    # script/plugin install git://github.com/spohlenz/acts_as_authenticated_user.git


Model Setup
-----------

The user model requires three fields: `login`, `hashed_password` and `salt` (all strings). This can be achieved with a migration such as:

    class CreateUsers < ActiveRecord::Migration
      def self.up
        create_table :users do |t|
          t.string :login
          t.string :hashed_password
          t.string :salt
          
          ... your custom user fields ...
        end
      end
      
      def self.down
        drop_table :users
      end
    end

The model can then be declared as an authenticated user with:

    class User < ActiveRecord::Base
      acts_as_authenticated_user
    end

Allowing the following behaviour:

    u = User.create(:login => 'sam', :password => 'foobar', :password_confirmation => 'foobar')
    User.authenticate('sam', 'foobar') #=> u
    User.authenticate('invalid', 'user') #=> nil
    
If you want to use another field for your main identifier (e.g. `email` instead of `login`), replace `login` in your database schema and call `acts_as_authenticated_user` with `:identifier => :email`.

*acts\_as\_authenticated\_user* will validate the presence of login and password but any extra validations will need to be defined in the User model. If you want to disable validations altogether (for example to define your own validation messages), declare `acts_as_authenticated_user :validate => false` in your User model. If you do this, be sure to define at least the following validations:

 - `validates_presence_of {identifier_column}`
 - `validates_uniqueness_of {identifier_column}`
 - `validates_presence_of :password, :if => :password_required?`
 - `validates_presence_of :password_confirmation, :if => :password_required?`
 - `validates_confirmation_of :password`

`acts_as_authenticated_user` does not define any validations as to the length of the password. You will need to specify these yourself.



Controller Setup
----------------

In your `application_controller.rb`:

    class ApplicationController < ActionController::Base
      authenticated_user
    end

Controllers and helpers have access to the `logged_in?` and `current_user` methods to determine the current login status.


Protecting a Controller
-----------------------

To protect a controller:

    class PrivatePageController < ApplicationController
      require_login
    
      def index
      end
    end

`require_login` takes an options hash accepting the same parameters as `before_filter` (e.g. :only and :except for per-action filtering). Other options include:

    :with => a callable object (Proc, lambda or method) which must return true for the user to have access to that page or controller
    :message => what to set flash[:error] to if the login check fails (defaults to 'Login required.')
    :login_path => the location of the login path (defaults to /login) [use a symbol if specifying a named route]
 
An example combining all of these is:

    class AdminController < ApplicationController
      require_login :only => [ :update, :create, :destroy ],
                    :with => Proc.new { |u| u.is_admin? },
                    :message => 'Admin privileges required',
                    :login_path => :admin_login_path
    end


Example (Handling login/logout)
-------------------------------

To handle login/logout, create a controller to contain authentication actions:

    class AccountController < ApplicationController
      def login
        process_login do |login|
          login.success { flash[:message] = 'Successful login' }
          login.failure { flash[:error] = 'Invalid login' }
        end
      end
    
      def logout
        process_logout do
          flash[:message] = 'Logged out'
        end
      end
    end

The login action should respond to both GET and POST (a GET request will render the login form, a POST request will process the login). The login form should pass :login (or your custom identifier) and :password in the POST params.

The `process_login` method yields a login object which responds to success and failure, allowing you to define a block to execute in case of success or failure (before any redirection). `process_login` also takes an optional parameter - the location to redirect to after a successful login.

Any request to logout will clear the current session. `process_logout` takes a single argument - the location to redirect to after logging out (optional, defaults to '/'). It also accepts an optional block which will be called on logout.


Cookie login (Remember me)
--------------------------

`acts_as_authenticated_user` supports cookie-based logins as long as you have the fields `remember_token (string)` and `remember_token_expires_at (datetime)` in your users table. The remember token and cookie is automatically set in `process_login` if `:remember_me` is set to '1' in your `params[:user]` hash.


To Be Implemented
-----------------

 - OpenID authentication


Copyright (c) 2008 Sam Pohlenz [<sam@sampohlenz.com>], released under the MIT license
