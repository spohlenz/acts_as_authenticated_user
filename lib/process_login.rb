module ActsAsAuthenticatedUser::ControllerExtensions
  class LoginHandler
    def initialize(controller, model, &block)
      @controller = controller
      @model = model
      instance_eval &block
    end
    
    def process(params, redirect_on_success)
      user = @model.authenticate(params[:login], params[:password])
      
      if user
        user.remember_me! if params[:remember_me] && @model.supports_remember_me?
        
        @controller.instance_eval { self.current_user = user }
        @controller.instance_eval(&success)
        @controller.instance_eval do
          redirect_to session[:previous_location] || redirect_on_success
          session[:previous_location] = nil
        end
      else
        @controller.instance_eval(&failure)
      end
    end
    
    def success(&block)
      @success = block if block_given?
      @success
    end
    
    def failure(&block)
      @failure = block if block_given?
      @failure
    end
  end
  
  module InstanceMethods
    def process_login(params, redirect_on_success='/', &block)
      if request.post?
        LoginHandler.new(self, user_model, &block).process(params, redirect_on_success)
      end
    end
    
    def process_logout(redirect='/')
      self.current_user = nil
      yield if block_given?
      redirect_to redirect
    end
  end
end
