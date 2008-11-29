module ActsAsAuthenticatedUser::ModelExtensions
  module ActsMethods
    def acts_as_authenticated_user(options={})
      unless acts_as_authenticated_user?
        extend ClassMethods
        include CoreInstanceMethods
        
        if remember_me_columns_exist?
          include RememberMeInstanceMethods
          class_inheritable_accessor :remember_me_duration
          self.remember_me_duration = 30.days
        end
        
        class_eval <<-EOF
          def self.identifier_column
            :#{options[:identifier] || :login}
          end
        EOF
        
        unless options[:validate] == false
          validates_presence_of identifier_column
          validates_uniqueness_of identifier_column
        
          validates_presence_of :password, :if => :password_required?
          validates_presence_of :password_confirmation, :if => :password_required?
          validates_confirmation_of :password
        end
        
        attr_accessor :password
        attr_protected :hashed_password, :salt
        
        before_save :encrypt_password
      end
    end
    
    def acts_as_authenticated_user?
      included_modules.include?(CoreInstanceMethods)
    end
  end
  
  module ClassMethods
    def authenticate(identifier, password)
      u = find(:first, :conditions => { identifier_column => identifier })
      u if u && encrypt(password, u.salt) == u.hashed_password
    end
    
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end
  
  private
    def remember_me_columns_exist?
      column_names.include?('remember_token') &&
        column_names.include?('remember_token_expires_at')
    end
  end
  
  module CoreInstanceMethods
  private
    def password_required?
      hashed_password.blank? || !password.blank?
    end
    
    def encrypt_password
      identifier = send(self.class.identifier_column)
      self.salt = digest(Time.now, identifier) if salt.blank?
      self.hashed_password = self.class.encrypt(password, salt) unless password.blank?
    end
    
    def digest(*args)
      Digest::SHA1.hexdigest("--#{args.join('--')}--")
    end
  end
  
  module RememberMeInstanceMethods
    def remember_me!
      self.remember_token = digest(Time.now, (1..10).map { rand })
      self.remember_token_expires_at = self.class.remember_me_duration.from_now
      save(false)
    end
    
    def forget_me!
      self.remember_token = nil
      self.remember_token_expires_at = nil
      save(false)
    end
  end
end
