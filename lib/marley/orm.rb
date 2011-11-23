module Marley
  module Orm
    module ReggaeHash
      def reggae_hash(keys,sub_key,prefix='',postfix='')
        keys.inject({}) do |h,k|
          i=send("#{prefix}_#{k}_#{postfix}".sub(/^_/,'').sub(/_$/,''))
          h[k.to_sym]=i.class==Hash ? i[subkey.call] : i
          h
        end
      end
    end
    module RestActions
      include ReggaeHash
      REST_ACTIONS=[:get_actions,:post_actions,:put_actions,:delete_actions]
      attr_accessor *REST_ACTIONS
      def rest_actions
        reggae_hash(['get','post','put','delete'],lambda {$request[:user].class},'','actions')
      end
    end
    module RestSection
      include ReggaeHash
      SECTION_PROPS='name','title','description','navigation'
      SECTION_PROPS.each {|p| attr_accessor :"section_#{p}"}
      def rest_section
        if SECTION_PROPS.find {|p| send(:"section_#{p}").to_s > ''}
          Marley::ReggaeSection.new(reggae_hash(SECTION_PROPS, lambda {$request[:user].class},'section'))
        end
      end
    end
  end
end
