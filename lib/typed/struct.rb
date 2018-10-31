# frozen_string_literal: true

module Typed
    class Struct
        # TODO: This has nothing to do in this gem, should be moved to application
        class Updater
            attr_reader :params, :target

            def initialize(target, params)
                @target = target
                @params = params
            end

            def assign(from, to: from, &value_builder)
                check_from(from)
                return unless params.key?(from)

                input_value = params[from]
                default_getter = proc { input_value }
                processed_value = (value_builder || default_getter).call(input_value)
                target.send("#{to}=", processed_value)
            end

            private

            def check_from(from)
                return if params.class.schema.key?(from)

                raise "Key #{from.inspect} does not exist on #{params.class}"
            end
        end

        class << self
            include Builder::BaseType

            def attribute(name, type = Typed.any)
                expected_type(type)

                name = name.to_sym

                raise Typed::InvalidType, "Property already defined: #{name}" if typed_attributes.key?(name)

                typed_attributes[name] = type
                define_method(name) { @_data.fetch(name) { Typed::Undefined } }
            end

            def schema
                @schema ||= ancestors.select { |a| Typed::Struct > a }.reverse.reduce({}) { |acc, clazz|
                    acc.merge(clazz.typed_attributes)
                }.freeze
            end

            def allow_extra_keys(new_flag)
                define_singleton_method(:allow_extra_keys?) { new_flag }
            end

            def allow_extra_keys?
                true
            end

            def typed_attributes
                @typed_attributes ||= {}
            end

            def process(data)
                result = parse_as_hash(data)
                result.ok ? Typed::Builder::Result.success(new(result)) : result
            end

            def parse_as_hash(input_data)
                return Typed::Builder::Result.success(input_data.to_h) if input_data.is_a?(self)

                # TODO: remove this hack
                unless input_data.is_a?(::Hash) || input_data.class.name == 'ActionController::Parameters'
                    return Typed::Builder::Result.failure { "Expected Hash, got #{input_data.inspect}" }
                end

                # Start by creating a new "clean" hash from input
                # This way, we can easily handle some variants (ActionController::Parameters, ...)
                clean_data = Hash.new { ::Typed::Undefined }
                input_data.each { |key, value| clean_data[key.to_sym] = value }

                # Check presence of extra keys
                extra_property = (clean_data.keys - schema.keys).first
                if extra_property && !allow_extra_keys?
                    return Typed::Builder::Result
                        .failure("Unknown property '#{extra_property}' of #{inspect}")
                end

                # Construct the final hash which will be stored internally to represent
                # Struct's data.
                output = schema.each_with_object({}) { |(name, type), acc|
                    result = type.process(clean_data[name])

                    unless result.ok
                        return Typed::Builder::Result.failure {
                            "Invalid property '#{name}' of #{inspect}: #{result.message}"
                        }
                    end

                    acc[name] = result.value unless Typed::Undefined.equal?(result.value)
                }.freeze

                Typed::Builder::Result.success(output)
            end
        end

        def updater(target)
            Updater.new(target, self)
        end

        def inspect
            attrs = self.class.schema.keys.map { |key| " #{key}=#{@_data[key].inspect}" }.join
            "#<#{self.class.name || self.class.inspect}#{attrs}>"
        end

        def to_h
            @_data
        end

        def [](key)
            raise Typed::InvalidType, "Unknown property: #{key.inspect}" unless self.class.schema.key?(key)

            @_data.fetch(key) { Typed::Undefined }
        end

        def ==(other)
            return true if other.equal?(self)
            return false unless other.instance_of?(self.class)

            @_data == other.instance_variable_get(:@_data)
        end

        def hash
            @_data.hash
        end

        def key?(key)
            @_data.key?(key)
        end

        def initialize(input_data = {})
            case input_data
            when Typed::Builder::Result then initialize_from_result(input_data)
            else initialize_from_result(self.class.parse_as_hash(input_data))
            end
        end

        private

        def initialize_from_result(result)
            raise Typed::InvalidValue, result.message unless result.ok

            @_data = result.value
        end
    end
end
