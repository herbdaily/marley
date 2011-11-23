
module Marley
  module Rest
    def rest_opts(name)
      meth_name="rest_#{name}"
      proc_name="#{meth_name}_proc"
      define_method "rest_#{name}" do |*args|
        if args[0]
          instance_variable_set meth_name,args[0]
          instance_variable_set proc_name,&block if block_given?
        else
          if instance_variable_get proc_name
            instance_variable_get(meth_name)[instance_variable_get(proc_name).call]
          else
            instance_variable_get(meth_name)
          end
        end
      end
    end
  end
end
