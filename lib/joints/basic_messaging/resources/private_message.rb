module Marley
  module Resources
    class PrivateMessage < MA::Message
      @actions_get=['reply','reply_all']
      def rest_cols; super << :recipients; end
      def current_user_role
        super || (recipients.match(/\b#{$request[:user][:name]}\b/) && "recipient")
      end
      def authorize_rest_get(meth)
        super && ($request[:user]==author || self.recipients.match(/\b#{$request[:user].name}\b/))
      end
      def authorize_rest_post(meth)
        meth.to_s > '' && (author_id==$request[:user][:id] || recipients.match(/\b#{$request[:user][:name]}\b/))
      end
      def self.authorize_rest_post(asdf)
        true #may need to change this, for now auth is handled in validation
      end
      def reply
        self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id],:recipients => author.name, :title => "re: #{title}"})
      end
      def reply_all
        foo=reply
        foo.recipients="#{author.name},#{recipients}".gsub(/\b(#{$request[:user][:name]})\b/,'').sub(',,',',')
        foo
      end
      def validate
        super
        validates_presence [:recipients]
        self.recipients.split(',').each do |recipient|
          if u=MR::User[:name => recipient]
            errors.add(:recipients, "You may only send PM's to Admins or Mods. #{recipient} is neither of those") unless (['Admin','Moderator'].include?(MR::User[:name => recipient].user_type) || [MR::Admin,MR::Moderator].include?($request[:user].class))
          else
            errors.add(:recipients, "Invalid user: #{recipient}")
          end
        end
      end
    end
  end
end
