module JSONAPIObjects
  module UnstrictProc
    refine Proc do
      def unstrict
        return self unless lambda?
        req_count = required_parameters.count
        Proc.new do |*arguments|
          if req_count > arguments.count
            (req_count - arguments.count).times { arguments << nil }
          elsif req_count < arguments.count
            arguments = req_count == 0 ? [] : arguments[0..(req_count - 1)]
          end
          call(*arguments) rescue puts "failed" && raise
        end
      end

      def parameters_hash
        parameters.each_with_object({}){ |(k, v), h| (h[k] ||= []) << v }
      end

      def required_parameters
        parameters_hash[:req] || []
      end

      def optional_parameters
        parameters_hash[:opt] || []
      end
    end
  end
end
