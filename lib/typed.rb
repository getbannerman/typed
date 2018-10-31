# frozen_string_literal: true

require 'typed/builder'
require 'typed/struct'
require 'typed/version'
require 'uri'
require 'active_support/time'

module Typed
    class InvalidValue < TypeError; end
    class InvalidType < TypeError; end

    class << self
        include Typed::Builder::BaseType

        def array(element_type = Typed.any)
            expected_type(element_type)

            Typed::Builder::ArrayType.new(element_type)
        end

        def any
            self
        end

        def null
            value(nil)
        end

        def value(expected_value)
            constrained(eql: call(expected_value))
        end
    end

    # Undefined is both:
    # - A placeholder used to represent an undefined value.
    # - The type used to represent this placeholder.
    module Undefined
        class << self
            include Typed::Builder::BaseType

            def process(value)
                if Undefined.equal?(value)
                    Typed::Builder::Result.success(value)
                else
                    Typed::Builder::Result.failure { 'Expected value undefined' }
                end
            end
        end
    end

    module Strict
        String = Typed.instance(::String)
        Symbol = Typed.instance(::Symbol)
        Int = Typed.instance(::Integer)
        Float = Typed.instance(::Float)
        Date = Typed.instance(::Date)
        True = Typed.value(true)
        False = Typed.value(false)
        Boolean = True | False
        Time = Typed.instance(::Time)
        DateTime = Typed.instance(::DateTime)
    end

    String = Strict::String.constructor(input: Strict::Int | Strict::Float | Strict::Symbol, &:to_s)

    Float = Strict::Float.constructor(
        input: Strict::String | Strict::Int,
        swallow: [TypeError, ArgumentError]
    ) { |value| Float(value) }

    Int = Strict::Int
        .constructor(
            input: Strict::String,
            swallow: [TypeError, ArgumentError]
        ) { |value| Integer(value) }
        .constructor(
            input: Float,
            swallow: [TypeError, ArgumentError]
        ) { |value|
            parsed = Integer(value)
            parsed == value ? parsed : value
        }

    Date = Strict::Date
        .constructor(
            input: String,
            swallow: [TypeError, ArgumentError, RangeError]
        ) { |value| ::Date.parse(value) }
        .constructor(input: Typed.instance(::Time), &:to_date)

    Boolean = Strict::Boolean.constructor(input: String) { |value|
        { 'true' => true, 'false' => false }.fetch(value) { value }
    }

    Time = (Strict::DateTime | Strict::Time)
        .constructor(input: String, swallow: [TypeError, ArgumentError]) { |value|
            ::ActiveSupport::TimeZone['UTC'].parse(value)
        }
        .constructor(input: Int | Float, swallow: [TypeError, ArgumentError]) { |value| ::Time.at(value) }

    UUID = String.constrained(format: /\A[a-f\d]{8}(-[a-f\d]{4}){3}-[a-f\d]{12}\z/)
        .constructor(input: String, &:downcase)

    URL = String.constrained(format: URI::DEFAULT_PARSER.make_regexp(%w[http https]))
end
