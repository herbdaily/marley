
require 'messages_joint.rb'

Marley.joint('section')
Marley.plugin('section').apply(MJ::Messages::Message,MR::User)
