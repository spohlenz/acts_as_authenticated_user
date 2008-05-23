ActiveRecord::Schema.define(:version => 0) do
  create_table :default_users, :force => true do |t|
    t.column :login, :string
    t.column :hashed_password, :string
    t.column :salt, :string
  end
end
