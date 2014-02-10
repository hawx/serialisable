require_relative '../spec_helper'

describe Serialisable::Selector do
  describe '#name' do
    let(:selector_name) { "some name" }
    subject { Serialisable::Selector.new(selector_name, nil) }

    it 'returns the name' do
      subject.name.must_equal selector_name
    end
  end

  describe Serialisable::Selector::Attribute do
    describe '#match' do
      describe 'when type not given' do
        subject { Serialisable::Selector::Attribute.new(nil, 'hey') }

        let(:xml) { '<el hey="1" what="5"/>' }
        let(:doc) { Nokogiri::XML(xml) }

        it 'returns the matching attribute' do
          subject.match(doc.children.first).must_equal "1"
        end
      end

      describe 'when symbol given as type' do
        subject { Serialisable::Selector::Attribute.new(nil, 'hey', :to_i) }

        let(:xml) { '<el hey="1" what="5"/>' }
        let(:doc) { Nokogiri::XML(xml) }

        it 'returns the matching attribute' do
          subject.match(doc.children.first).must_equal 1
        end
      end

      describe 'when object responding to #parse given as type' do
        let(:type) { Class.new { def parse(v); v.to_i; end }.new }
        subject { Serialisable::Selector::Attribute.new(nil, 'hey', type) }

        let(:xml) { '<el hey="1" what="5"/>' }
        let(:doc) { Nokogiri::XML(xml) }

        it 'returns the matching attribute' do
          subject.match(doc.children.first).must_equal 1
        end
      end
    end
  end

  describe Serialisable::Selector::Node do
    describe '#match' do
      describe 'when type not given' do
        subject { Serialisable::Selector::Node.new(nil, 'hey') }

        let(:xml) { '<el><hey>5</hey><what>6</what></el>' }
        let(:doc) { Nokogiri::XML(xml) }

        it 'returns the matching node' do
          subject.match(doc.children.first).must_equal "5"
        end
      end

      describe 'when symbol given as type' do
        subject { Serialisable::Selector::Node.new(nil, 'hey', :to_i) }

        let(:xml) { '<el><hey>5</hey><what>6</what></el>' }
        let(:doc) { Nokogiri::XML(xml) }

        it 'returns the matching node' do
          subject.match(doc.children.first).must_equal 5
        end
      end

      describe 'when object responding to #parse given as type' do
        let(:type) { Class.new { def parse(v); v.to_i; end }.new }
        subject { Serialisable::Selector::Node.new(nil, 'hey', type) }

        let(:xml) { '<el><hey>5</hey><what>6</what></el>' }
        let(:doc) { Nokogiri::XML(xml) }

        it 'returns the matching node' do
          subject.match(doc.children.first).must_equal 5
        end
      end
    end
  end

  describe Serialisable::Selector::Nodes do
    describe '#match' do
      describe 'when no type given' do
        subject { Serialisable::Selector::Nodes.new(nil, 'hey') }

        let(:xml) { '<el><hey>5</hey><hey>6</hey><what>7</what></el>' }
        let(:doc) { Nokogiri::XML(xml) }

        it 'returns the matching nodes' do
          subject.match(doc.children.first).must_equal ['5', '6']
        end
      end

      describe 'when symbol given as type' do
        subject { Serialisable::Selector::Nodes.new(nil, 'hey', :to_i) }

        let(:xml) { '<el><hey>5</hey><hey>6</hey><what>7</what></el>' }
        let(:doc) { Nokogiri::XML(xml) }

        it 'returns the matching nodes' do
          subject.match(doc.children.first).must_equal [5, 6]
        end
      end

      describe 'when object responding to #parse given as type' do
        let(:type) { Class.new { def parse(v); v.to_i; end }.new }
        subject { Serialisable::Selector::Nodes.new(nil, 'hey', type) }

        let(:xml) { '<el><hey>5</hey><hey>6</hey><what>7</what></el>' }
        let(:doc) { Nokogiri::XML(xml) }

        it 'returns the matching nodes' do
          subject.match(doc.children.first).must_equal [5, 6]
        end
      end
    end
  end

  describe Serialisable::Selector::Nested do
    describe '#match' do
      let(:root)   { mock }
      let(:nested) { mock }
      let(:parsed) { mock }
      subject { Serialisable::Selector::Nested.new(nil, nested, nil) }

      before {
        nested
          .expects(:send)
          .with(:__deserialise, root)
          .returns(parsed)
      }

      it 'calls the private #__deserialise method' do
        subject.match(root).must_equal parsed
      end
    end
  end

  describe Serialisable::Selector::NestedMultiple do
    describe '#match' do
      let(:root)   { mock }
      let(:nested) { mock }
      let(:parsed) { mock }
      subject { Serialisable::Selector::NestedMultiple.new(nil, nested, nil) }

      before {
        nested
          .expects(:send)
          .with(:__deserialise_all, root)
          .returns(parsed)
      }

      it 'calls the private #__deserialise_all method' do
        subject.match(root).must_equal parsed
      end
    end
  end
end
