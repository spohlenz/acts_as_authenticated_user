ActiveRecord::Schema.define(:version => 0) do
  create_table :default_users, :force => true do |t|
    t.column :login, :string
    t.column :hashed_password, :string
    t.column :salt, :string
  end
  
  create_table :email_users, :force => true do |t|
    t.column :email, :string
    t.column :hashed_password, :string
    t.column :salt, :string
  end
  
  create_table :no_validation_users, :force => true do |t|
    t.column :login, :string
    t.column :hashed_password, :string
    t.column :salt, :string
  end
  
  create_table :memorable_users, :force => true do |t|
    t.column :login, :string
    t.column :hashed_password, :string
    t.column :salt, :string
    t.column :remember_token, :string
    t.column :remember_token_expires_at, :datetime
  end
  
  create_table :open_id_users, :force => true do |t|
    t.column :login, :string
    t.column :hashed_password, :string
    t.column :salt, :string
    t.column :identity_url, :string
  end 
end
