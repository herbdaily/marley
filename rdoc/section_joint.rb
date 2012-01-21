
require 'messages_joint.rb'

Marley.joint('section')
Marley.plugin('section').apply(MR.constants)

module Marley
  module Resources
    def User.section_link
      super.update(:title => 'Account',:url => current_user.url)
    end
  end
end
