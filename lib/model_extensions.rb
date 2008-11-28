module ActsAsAuthenticatedUser::ModelExtensions
  module ActsMethods
    def acts_as_authenticated_user(options={})
      unless acts_as_authenticated_user?
        extend ClassMethods
        include InstanceMethods
        
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
      included_modules.include?(InstanceMethods)
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
  end
  
  module InstanceMethods
  private
    def password_required?
      hashed_password.blank? || !password.blank?
    end
    
    def encrypt_password
      identifier = send(self.class.identifier_column)
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{identifier}--") if salt.blank?
      self.hashed_password = self.class.encrypt(password, salt) unless password.blank?
    end
  end
end
