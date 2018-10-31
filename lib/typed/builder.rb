# frozen_string_literal: true

require 'dry-logic'
require 'dry/logic/rule_compiler'
require 'dry/logic/predicates'

module Typed
    module Builder
        # Entrypoint
        def self.any
            AnyHandler.instance
        end

        Result = ::Struct.new(:ok, :value, :message)
        class Result
            attr_reader :ok, :value

            def initialize(ok, value, message)
                @ok = ok
                @value = value
                @failure_block = message
            end

            def message
                @message ||= @failure_block.call
            end

            class << self
                def success(value)
                    new(true, value, nil)
                end

                def failure(&failure_block)
                    new(false, nil, failure_block)
                end
            end
        end

        module BaseType
            def nullable
                Typed.null | self
            end

            def missable
                Typed.value(Undefined) | self
            end

            def default(new_value = Typed::Undefined, &block)
                call(new_value) unless block
                block ||= -> { new_value }
                DefaultType.new(self) { call(block.call) }
            end

            def instance(expected_class)
                constrained(type: expected_class)
            end

            def enum(*values)
                constrained(included_in: values.map { |value| call(value) })
            end

            def |(other)
                expected_type other

                SumType.new(self, other)
            end

            def constructor(input: Typed.any, swallow: [], &block)
                expected_type(input)
                return self unless block_given?

                CoerceType.new(input, self, swallow, &block)
            end

            def constrained(**dry_options, &constraint)
                base = constraint ? ConstrainedType.new(self, &constraint) : self
                base = base.dry_constrained(**dry_options) unless dry_options.empty?
                base
            end

            def call(*args)
                result = process((args + [Typed::Undefined]).first)
                return result.value if result.ok

                raise InvalidValue, result.message
            end

            def process(value)
                Typed::Builder::Result.success(value)
            end

            protected

            def dry_constrained(**options)
                predicate = ::Dry::Logic::RuleCompiler.new(::Dry::Logic::Predicates).call(
                    options.map { |key, val|
                        ::Dry::Logic::Rule::Predicate.new(
                            ::Dry::Logic::Predicates[:"#{key}?"]
                        ).curry(val).to_ast
                    }
                ).reduce(:and)

                constrained do |value|
                    "#{value.inspect} violates #{predicate}" unless predicate.call(value).success?
                end
            end

            private

            def expected_type(type)
                raise InvalidType, "Not a Typed type: #{type.inspect}" unless type.is_a?(BaseType)
            end
        end

        class ArrayType
            include BaseType

            def initialize(element_type)
                @element_type = element_type
            end

            def process(value)
                return Result.failure { "Invalid collection: #{value.inspect}" } unless value.respond_to?(:each)

                new_value = []

                value.each do |element|
                    element_result = element_type.process(element)
                    return element_result unless element_result.ok

                    new_value << element_result.value
                end

                Result.success(new_value)
            end

            private

            attr_reader :base_type, :element_type
        end

        class ConstrainedType
            include BaseType

            def initialize(base_type, &constraint)
                @base_type = base_type
                @constraint = constraint
            end

            def process(value)
                result = base_type.process(value)
                return result unless result.ok

                error = constraint.call(result.value)
                return result unless error

                Result.failure { error }
            end

            private

            attr_reader :base_type, :constraint
        end

        class DefaultType
            include BaseType

            def initialize(base_type, &default_value)
                @base_type = base_type
                @default_value = default_value
            end

            def process(value)
                new_value = Typed::Undefined.equal?(value) ? default_value.call : value
                base_type.process(new_value)
            end

            private

            attr_reader :default_value, :base_type
        end

        class SumType
            include BaseType

            def initialize(type_a, type_b)
                @type_a = type_a
                @type_b = type_b
            end

            def process(value)
                result = type_a.process(value)
                return result if result.ok

                type_b.process(value)
            end

            private

            attr_reader :type_a, :type_b
        end

        class CoerceType
            include BaseType

            def initialize(input_type, return_type, swallow, &coercion)
                @input_type = input_type
                @return_type = return_type
                @coercion = coercion
                @swallow = swallow
            end

            def process(value)
                # No coercion needed
                passthrough_result = return_type.process(value)
                return passthrough_result if passthrough_result.ok

                # Check input_type enables this coercion
                input_result = input_type.process(value)

                if input_result.ok
                    coerced_value =
                        begin
                            coercion.call(input_result.value)
                        rescue *swallow
                            input_result.value
                        end
                    return return_type.process(coerced_value)
                end

                passthrough_result
            end

            private

            attr_reader :input_type, :return_type, :coercion, :swallow
        end
    end
end
