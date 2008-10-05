module RR
  module DoubleDefinitions
    module Strategies
      module Implementation
        class Proxy < Strategy
          def name
            "proxy"
          end

          protected
          def do_call
            definition.proxy
            definition.after_call(&handler) if handler
          end
        end
      end
    end
  end
end