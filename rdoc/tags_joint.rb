require 'user_joint.rb'

DB.create_table :tags do
  primary_key :id
  integer :user_id
  text :tag
end
DB.create_table :messages_tags do
  primary_key :id
  integer :user_id
  integer :tag_id
  integer :message_id
end
Marley.joint('tags')
Marley.plugin(:private_tagging).apply('Secret')
Marley.plugin(:public_tagging).apply('Announcement')
