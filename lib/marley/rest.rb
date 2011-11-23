
module Marley
  module Rest
    def rest_opts(name)
      meth_name="@_rest_#{name}"
      proc_name="#{meth_name}_proc"
      m=Module.new do
        define_method "rest_#{name}" do |*args|
          if args[0]
            instance_variable_set meth_name,args[0]
            instance_variable_set proc_name,args[1] if args[1]
          else
            if instance_variable_get proc_name
              instance_variable_get(meth_name)[instance_variable_get(proc_name).call]
            else
              instance_variable_get(meth_name)
            end
          end
        end
      end
      extend m
    end
  end
end
