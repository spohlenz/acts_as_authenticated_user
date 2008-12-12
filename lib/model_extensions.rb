module ActsAsAuthenticatedUser::ModelExtensions
  module ActsMethods
    def acts_as_authenticated_user(options={})
      unless acts_as_authenticated_user?
        extend ClassMethods
        include CoreInstanceMethods
        
        if supports_remember_me?
          include RememberMeInstanceMethods
          
          cattr_accessor :remember_me_duration
          self.remember_me_duration = 30.days
        end
        
        if supports_openid?
          include OpenIdInstanceMethods
          before_validation :normalize_identity_url
        end
        
        cattr_accessor :identifier_column
        self.identifier_column = options[:identifier] || :login
        
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
    
    def supports_remember_me?
      @supports_remember_me ||=
        column_names.include?('remember_token') &&
        column_names.include?('remember_token_expires_at') rescue false
    end
    
    def supports_openid?
      @supports_openid ||= column_names.include?('identity_url') rescue false
    end
  end
  
  module CoreInstanceMethods
  private
    def password_required?
      return false if self.class.supports_openid? && identity_url?
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
    
    def remember_token_expired?
      remember_token_expires_at.nil? || remember_token_expires_at < Time.now
    end
  end
  
  module OpenIdInstanceMethods
    def normalize_identity_url
      self.identity_url = OpenIdAuthentication.normalize_url(identity_url) if identity_url?
    end
  end
end
