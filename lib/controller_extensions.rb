module ActsAsAuthenticatedUser::ControllerExtensions
  module InstanceMethods
  protected
    def current_user
      @current_user ||= user_model.find_by_id(session[:user])
    end

    def current_user=(user)
      @current_user = user
      session[:user] = user ? user.id : nil
    end
    
    def logged_in?
      !!current_user
    end
    
    def check_login
      unless current_user && user_conditions(current_user)
        flash[:error] = login_message
        session[:previous_location] = request.request_uri
        redirect_to login_action
      end
    end
  end
  
  module ClassMethods
    def require_login(options={})
      user_model = options.delete(:user_model) || User
      define_method(:user_model) { user_model }
      
      conditions = options.delete(:with) || Proc.new { true }
      define_method(:user_conditions) { |u| conditions.call(u) }
      
      message = options.delete(:message) || 'Login required.'
      define_method(:login_message) { message }
      
      login_action = options.delete(:login_path) || :login_path
      define_method(:login_action) { login_action.is_a?(Symbol) ? send(login_action) : login_action }
      
      protected :user_model, :user_conditions, :login_message, :login_action
      
      skip_before_filter :check_login, options
      before_filter :check_login, options
    end
    
    def skip_login(options={})
      skip_before_filter :check_login, options
    end
  end
  
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.send(:extend, ClassMethods)
    base.helper_method :current_user, :logged_in?
  end
end
