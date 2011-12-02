
module Marley
  module Resources
    class Post < Message
      @actions_get=['reply']
      def current_user_role
        super || 'reader'
      end
      def authorize_rest_post(meth);true;end
      def reply
        self.class.new({:parent_id => self[:id],:author_id => $request[:user][:id], :title => "re: #{title}"})
      end
    end
  end
end
