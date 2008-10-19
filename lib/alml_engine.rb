# Usage: alml_engine :attr1, :attr2, :attr3
module Alml
  module Engine

    def self.included(klass)
      klass.extend ActMethods
    end

    module ActMethods
    
      def alml_engine(*attributes)
        # only need to define these once on a class
        unless included_modules.include?(InstanceMethods)
          include InstanceMethods
        end
      end
    
    end

    module InstanceMethods
    end
  end
end