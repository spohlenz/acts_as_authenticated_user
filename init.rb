ActiveRecord::Base.send(:extend, ActsAsAuthenticatedUser::ModelExtensions::ActsMethods)
ActionController::Base.send(:include, ActsAsAuthenticatedUser::ControllerExtensions)
