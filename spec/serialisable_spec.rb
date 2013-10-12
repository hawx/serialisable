require_relative 'spec_helper'

describe Serialisable do

  describe '#deserialise' do
    describe 'with one node' do

      subject {
        Class.new {
          extend Serialisable

          root 'root'
          element :node, 'node'
        }
      }

      let(:xml) {
        '<?xml version="1.0" encoding="utf-8"?><root><node>value</node></root>'
      }

      it 'takes xml and returns an object' do
        subject.deserialise(xml).node.must_equal 'value'
      end
    end

    describe 'with an element to parse' do

      subject {
        require 'time'

        Class.new {
          extend Serialisable

          root 'root'
          element :time, 'time', Time
        }
      }

      let(:xml) {
        '<?xml version="1.0" encoding="utf-8"?><root><time>2013-07-04T13:23:34Z</time></root>'
      }

      it 'takes xml and returns an object, with types parsed' do
        subject.deserialise(xml).time.must_equal Time.utc(2013, 7, 4, 13, 23, 34)
      end
    end
  end

  describe 'with a nested serialisable' do

    subject {
      Class.new {
        extend Serialisable

        root 'songs'
        element :song, Class.new {
          extend Serialisable

          root 'song'
          element :artist, 'artist'
          element :name, 'name'
        }
      }
    }

    let(:xml) {
      <<EOS
<?xml version="1.0" encoding="utf-8"?>
<songs>
  <song>
    <artist>Arctic Monkeys</artist>
    <name>505</name>
  </song>
</songs>
EOS
    }

    it 'deserialises the nested object correctly' do
      result = subject.deserialise(xml)

      result.song.artist.must_equal 'Arctic Monkeys'
      result.song.name.must_equal '505'
    end
  end

  describe 'with a list of nested objects' do
    subject {
      Class.new {
        extend Serialisable

        root 'songs'
        elements :songs, Class.new {
          extend Serialisable

          root 'song'
          element :artist, 'artist'
          element :name, 'name'
        }
      }
    }

    let(:xml) {
      <<EOS
<?xml version="1.0" encoding="utf-8"?>
<songs>
  <song>
    <artist>Arctic Monkeys</artist>
    <name>505</name>
  </song>
  <song>
    <artist>Aphex Twin</artist>
    <name>Windowlicker</name>
  </song>
</songs>
EOS
    }

    it 'takes xml and returns an object with a list of nested objects' do
      result = subject.deserialise(xml)

      result.songs.length.must_equal 2

      result.songs[0].artist.must_equal 'Arctic Monkeys'
      result.songs[0].name.must_equal '505'

      result.songs[1].artist.must_equal 'Aphex Twin'
      result.songs[1].name.must_equal 'Windowlicker'
    end
  end
end
