require_relative 'spec_helper'

describe Serialisable do

  subject {
    Class.new {
      extend Serialisable

      root 'root'
      element :node, 'node'
    }
  }

  describe '#deserialise' do
    let(:xml) {
      '<?xml version="1.0" encoding="utf-8"?><root><node>value</node></root>'
    }

    it 'takes xml and returns an object' do
       subject.deserialise(xml).node.must_equal 'value'
    end
  end
end
