require 'user_joint.rb'
DB.create_table :messages do
  primary_key :id
  text :message_type
  integer :author_id
  text :recipients
  integer :thread_id
  integer :parent_id
  datetime :date_created
  datetime :date_updated
  text :title
  clob :message
end
Marley.joint 'basic_messaging'
Marley.joint 'basic_menu_system'

MR::User.delete
@client=Marley::TestClient.new(:resource_name => 'user')
['user1','user2','admin'].each do |un|
  MR::User.new(:name => un,:password => 'asdfasdf', :confirm_password => 'asdfasdf').save
end
MR::User[:name => 'admin'].update(:user_type => 'Admin')
@admin_auth=['admin','asdfasdf']
@user1_auth=['user1','asdfasdf']
@user2_auth=['user2','asdfasdf']

