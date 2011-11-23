module Marley
  module Orm
    module ReggaeHash
      attr_accessor :reggae_dynamic_key
      def reggae_hash(keys,prefix='',postfix='')
        keys.inject({}) do |h,k|
          i=send("#{prefix}_#{k}_#{postfix}".sub(/^_/,'').sub(/_$/,''))
          h[k.to_sym]=i.class==Hash ? i[@reggae_dynamic_key.call] : i
          h
        end
      end
    end
    module RestActions
      include ReggaeHash
      @reggae_dynamic_key=lambda {$request[:user].class}
      REST_ACTIONS=['get','post','put','delete']
      REST_ACTIONS.each {|p| attr_accessor :"#{p}_actions"}
      def rest_actions
        reggae_hash(REST_ACTIONS,'','actions')
      end
    end
    module RestSection
      include ReggaeHash
      @reggae_dynamic_key=lambda {$request[:user].class}
      SECTION_PROPS=['name','title','description','navigation']
      SECTION_PROPS.each {|p| attr_accessor :"section_#{p}"}
      def rest_section
        if SECTION_PROPS.find {|p| send(:"section_#{p}").to_s > ''}
          Marley::ReggaeSection.new(reggae_hash(SECTION_PROPS,'section'))
        end
      end
    end
  end
end
