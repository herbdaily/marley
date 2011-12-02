require 'sanitize'
module Marley
  module Abstract
    class Message < Sequel::Model
      plugin :single_table_inheritance, :message_type, :model_map => lambda{|v| v ? MR.const_get(v.to_s) : ''}, :key_map => lambda{|klass|klass.name.sub(/.*::/,'')}
      # CHANGE NEEDED:tree is unnecessary, instead, select by thread_id, order by parent_id, inject [] for nesting.  Should be much faster.
      plugin :tree
      many_to_one :author, :class => :'Marley::Resources::User'
      @owner_col=:author_id
      def rest_cols; [:id,:author_id,:message,:title,:parent_id]; end
      def write_cols; new? ?  rest_cols - [:id] : []; end
      def required_cols; write_cols - [:parent_id]; end
      def rest_schema
        super << [:text,:author,RESTRICT_RO,author.to_s]
      end
      def authorize_rest_get(meth)
        current_user_role && (meth.nil? || self.class.actions_get.include?(meth))
      end
      def authorize_rest_put(meth); false; end
      def after_initialize
        super
        if new?
          self.thread_id=parent ? parent.thread_id : Message.select(:max.sql_function(:thread_id).as(:tid)).all[0][:tid].to_i + 1
        end
      end
      def before_save
        self.message=Sanitize.clean(self.message,:elements => %w[blockquote em strong ul ol li p code])
      end
      def validate
        validates_presence [:author,:message,:title]
        validates_type MR::User, :author
      end
      def thread
        children.length > 0 ? to_a << children.map{|m| m.thread} : to_a
      end
    end
  end
end
