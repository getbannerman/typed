# frozen_string_literal: true

require 'coveralls'
Coveralls.wear! do
    add_filter 'spec'
end

require 'typed'

module IsExpectedBlock
    def is_expected_block
        expect { subject }
    end
end

RSpec.configure do |config|
    config.include IsExpectedBlock
end
