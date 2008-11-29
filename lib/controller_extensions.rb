module ActsAsAuthenticatedUser::ControllerExtensions
  module InstanceMethods
  protected
    def check_login
      unless current_user && user_conditions(current_user)
        flash[:error] = login_message
        session[:previous_location] = request.request_uri
        redirect_to login_action
      end
    end
  end
  
  module ClassMethods
    def authenticated_user(options={})
      model_class = options[:model] || User
      model = model_class.to_s.underscore
      
      class_eval <<-EOF
      protected
        def self.user_model
          #{model_class}
        end
        
        def user_model
          self.class.user_model
        end
        
        def current_#{model}
          @current_#{model} ||= user_model.find_by_id(session[:#{model}]) if session[:#{model}]
        end
        
        def current_#{model}=(u)
          @current_#{model} = u
          session[:#{model}] = u ? u.id : nil
        end
        
        def logged_in?
          !!current_#{model}
        end
        
        helper_method :current_#{model}, :logged_in?
      EOF
    end
    
    def require_login(options={})
      conditions = options.delete(:with) || Proc.new { true }
      define_method(:user_conditions) { |u| conditions.call(u) }
      
      login_action = options.delete(:login_path) || :login_path
      define_method(:login_action) { login_action.is_a?(Symbol) ? send(login_action) : login_action }
      
      message = options.delete(:message) || 'Login required.'
      model = user_model.to_s.underscore
      
      class_eval <<-EOF
        def check_login
          unless logged_in? && user_conditions(current_#{model})
            flash[:error] = "#{message}"
            session[:previous_location] = request.request_uri
            redirect_to login_action
          end
        end
      EOF
      
      protected :user_model, :user_conditions, :login_action, :check_login
      
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
  end
end
