module ActsAsAuthenticatedUser::ModelExtensions
  module ActsMethods
    def acts_as_authenticated_user(options={})
      unless acts_as_authenticated_user?
        validates_presence_of :login
        validates_uniqueness_of :login
    
        validates_presence_of :password, :password_confirmation, :if => :password_required?
        validates_confirmation_of :password
    
        attr_accessor :password
        attr_protected :hashed_password, :salt
    
        before_save :encrypt_password
    
        extend ClassMethods
        include InstanceMethods
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
  end

  module InstanceMethods
  private
    def password_required?
      hashed_password.blank? || !password.blank?
    end
  
    def encrypt_password
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if salt.blank?
      self.hashed_password = self.class.encrypt(password, salt)
    end
  end
end
