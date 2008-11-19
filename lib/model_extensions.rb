module ActsAsAuthenticatedUser::ModelExtensions
  module ActsMethods
    def acts_as_authenticated_user(options={})
      unless acts_as_authenticated_user?
        extend ClassMethods
        include InstanceMethods
        
        setup_validation :validates_presence_of, :login, options[:messages]
        setup_validation :validates_uniqueness_of, :login, options[:messages]
        
        setup_validation :validates_presence_of, :password, options[:messages], :if => :password_required?
        setup_validation :validates_presence_of, :password_confirmation, options[:messages], :if => :password_required?
        setup_validation :validates_confirmation_of, :password, options[:messages]
        
        attr_accessor :password
        attr_protected :hashed_password, :salt
        
        before_save :encrypt_password
      end
    end
    
    def acts_as_authenticated_user?
      included_modules.include?(InstanceMethods)
    end
  end
  
  module ClassMethods
    def authenticate(login, password)
      u = find_by_login(login)
      u if u && encrypt(password, u.salt) == u.hashed_password
    end
    
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end
    
  private
    def setup_validation(validation, attribute, messages, options={})
      message_name = "#{validation}_#{attribute}".to_sym
      options[:message] = messages[message_name] if messages && messages[message_name]
      send(validation, attribute, options)
    end
  end
  
  module InstanceMethods
  private
    def password_required?
      hashed_password.blank? || !password.blank?
    end
    
    def encrypt_password
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if salt.blank?
      self.hashed_password = self.class.encrypt(password, salt) unless password.blank?
    end
  end
end
