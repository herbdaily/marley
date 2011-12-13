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
Marley.plugin(:tagging,{:tag_type => 'private'}).apply('Secret')
Marley.plugin(:tagging,{:tag_type => 'private'}).apply('Announcement')
Marley.plugin(:tagging,{:tag_type => 'public'}).apply('Announcement')
