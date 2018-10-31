# frozen_string_literal: true

require 'spec_helper'

describe Typed do
    describe 'predefined types' do
        subject { type.call(value) }

        describe 'Undefined' do
            let(:type) { Typed::Undefined }

            context do
                let(:value) { Typed::Undefined }
                it { is_expected.to eq(Typed::Undefined) }
            end

            context do
                let(:value) { nil }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end
        end

        describe 'String' do
            let(:type) { Typed::String }

            context do
                let(:value) { 'lol' }
                it { is_expected.to eq('lol') }
            end

            context do
                let(:value) { nil }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end

            context do
                let(:value) { 12 }
                it { is_expected.to eq('12') }
            end
        end

        describe 'Time' do
            let(:now) { Time.now.round }
            let(:type) { Typed::Time }

            context do
                let(:value) { now }
                it { is_expected.to eq now }
            end

            context do
                let(:value) { now.to_datetime }
                it { is_expected.to eq now }
            end

            context do
                let(:value) { now.iso8601 }
                it { is_expected.to eq now }
            end

            context do
                let(:value) { 'fred' }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end
        end

        describe 'UUID' do
            let(:type) { Typed::UUID }

            context do
                let(:value) { '13CD8b90-d70f-490a-8872-f11b60afe80c' }
                it { is_expected.to eq '13cd8b90-d70f-490a-8872-f11b60afe80c' }
            end

            context do
                let(:value) { 'abcdef123' }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end
        end

        describe '.array' do
            context do
                let(:type) { Typed.array(Typed::Float | Typed::UUID) }
                let(:value) { ['13CD8b90-d70f-490a-8872-f11b60afe80c', '45.2', 12] }
                it { is_expected.to eq ['13cd8b90-d70f-490a-8872-f11b60afe80c', 45.2, 12] }
            end
        end

        describe 'Integer' do
            let(:type) { Typed.array(Typed::Int) }

            context do
                let(:value) { [-4, 0, 10, '12', 24.0, '-10.00'] }
                it { is_expected.to eq [-4, 0, 10, 12, 24, -10.00] }
            end

            context do
                let(:value) { ['24.1'] }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end

            context do
                let(:value) { [0.001] }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end
        end

        describe 'Date' do
            let(:type) { Typed.array(Typed::Date) }

            context do
                let(:value) { [20_100_101, '2012-03-03', Date.parse('2015-08-01')] }

                it {
                    is_expected.to eq [
                        Date.parse('2010-01-01'),
                        Date.parse('2012-03-03'),
                        Date.parse('2015-08-01')
                    ]
                }
            end

            context do
                let(:value) { 'not a date clearly' }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end
        end

        describe 'Boolean' do
            let(:type) { Typed.array(Typed::Boolean) }

            context do
                let(:value) { [true, false, 'true', 'false'] }
                it { is_expected.to eq [true, false, true, false] }
            end

            context do
                let(:value) { %w[true foobar] }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end
        end

        describe '.enum' do
            let(:type) { Typed::Int.enum(1, 3, 5) }

            context 'invalid enum value wrt. base type' do
                let(:type) { Typed::Int.enum(12, 13.5) }
                it { expect { type }.to raise_error Typed::InvalidValue }
            end

            context do
                let(:value) { 30 }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end

            context do
                let(:value) { 5 }
                it { is_expected.to eq 5 }
            end
        end

        describe '.sum' do
            let(:type) { Typed::Strict::Int | Typed::Strict::Float | Typed::Strict::Boolean }

            context do
                let(:value) { 12 }
                it { is_expected.to eq 12 }
            end

            context do
                let(:value) { 12.5 }
                it { is_expected.to eq 12.5 }
            end

            context do
                let(:value) { false }
                it { is_expected.to eq false }
            end

            context do
                let(:value) { 'oops' }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end
        end

        describe '.missable' do
            let(:type) { Typed::Int.missable }

            it { expect(type.call).to eq Typed::Undefined }
            it { expect(type.call(2)).to eq 2 }
            it { expect { type.call('lol') }.to raise_error Typed::InvalidValue }
        end

        describe '.nullable' do
            let(:type) { Typed::Int.nullable }

            it { expect { type.call }.to raise_error Typed::InvalidValue }
            it { expect(type.call(nil)).to eq nil }
            it { expect(type.call(2)).to eq 2 }
        end

        describe '.default' do
            let(:type) { Typed::Int.default(12) }

            it { expect(type.call).to eq 12 }
            it { expect(type.call('13')).to eq 13 }
        end
    end

    describe 'structs' do
        class A < Typed::Struct
            attribute :a, Typed::String.nullable.missable
        end

        class B < A
            attribute :b, A.nullable
        end

        class C < B
            attribute :c, Typed::Int.missable.default('4')
        end

        subject { C.new(value) }

        describe 'init from data' do
            context do
                let(:value) { { 'b' => nil } }
                it { is_expected.to have_attributes(b: nil, a: Typed::Undefined, c: 4) }
                it { is_expected.to have_attributes(to_h: { b: nil, c: 4 }) }
            end

            context do
                let(:value) { { 'c' => '32', a: nil, b: { a: 'coucou' } } }
                it { is_expected.to have_attributes(b: have_attributes(a: 'coucou'), a: nil, c: 32) }
            end

            context do
                let(:value) { nil }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end

            context do
                let(:value) { { b: { a: [] } } }
                it { is_expected_block.to raise_error Typed::InvalidValue }
            end
        end

        context 'init from instance' do
            let(:b) { B.new(a: 'coucou', b: nil) }
            let(:a) { A.new(b) }

            it { expect(a).to have_attributes(a: 'coucou') }
        end
    end
end
