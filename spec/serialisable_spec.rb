require_relative 'spec_helper'

describe Serialisable do

  describe '#element' do
    describe 'with a single element' do

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

    describe 'with an single element with a type to parse' do
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

      it 'takes xml and returns an object with the type parsed' do
        subject.deserialise(xml).time.must_equal Time.utc(2013, 7, 4, 13, 23, 34)
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

    describe 'with a nested serialisable given a root' do
      subject {
        track = Class.new {
          extend Serialisable

          root 'track'
          element :artist, 'artist'
          element :name, 'name'
        }

        Class.new {
          extend Serialisable

          root 'songs'
          element :song, 'song', track
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
  end

  describe '#elements' do
    describe 'with a single list of elements' do
      subject {
        require 'time'

        Class.new {
          extend Serialisable

          root 'root'
          elements :times, 'time', Time
        }
      }

      let (:xml) {
        '<?xml version="1.0" encoding="utf-8"?><root><time>2013-05-06T00:00:00Z</time><time>2013-06-07T00:00:00Z</time></root>'
      }

      it 'takes xml and returns an object with a list of results' do
        times = subject.deserialise(xml).times
        times.must_equal [Time.utc(2013, 5, 6), Time.utc(2013, 6, 7)]
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

    describe 'with a list of nested objects given a root' do
      subject {
        track = Class.new {
          extend Serialisable

          root 'track'
          element :artist, 'artist'
          element :name, 'name'
        }

        Class.new {
          extend Serialisable

          root 'songs'
          elements :songs, 'song', track
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

  describe '#attribute' do
    describe 'with a single attribute' do
      subject {
        Class.new {
          extend Serialisable

          root 'item'
          attribute :id, 'id'
        }
      }

      let(:xml) {
        '<?xml version="1.0" encoding="utf-8"?><item id="1234" />'
      }

      it 'takes xml and returns an object with the attribute deserialised' do
        subject.deserialise(xml).id.must_equal '1234'
      end
    end

    describe 'with an attribute with a type' do
      subject {
        require 'time'
        Class.new {
          extend Serialisable

          root 'item'
          attribute :at, 'at', Time
        }
      }

      let(:xml) {
        '<?xml version="1.0" encoding="utf-8"?><item at="2013-10-10T15:30:34Z" />'
      }

      it 'takes xml and returns an object with the attribute parsed' do
        subject.deserialise(xml).at.must_equal Time.utc(2013, 10, 10, 15, 30, 34)
      end
    end

    describe 'with an attribute on a nested object' do
      subject {
        Class.new {
          extend Serialisable

          root 'items'
          element :item, Class.new {
            extend Serialisable

            root 'item'
            attribute :id, 'id'
          }
        }
      }

      let(:xml) {
        '<?xml version="1.0" encoding="utf-8"?><items><item id="1234" /></items>'
      }

      it 'takes xml and returns an object with the attribute deserialised' do
        subject.deserialise(xml).item.id.must_equal '1234'
      end
    end

    describe 'with an attribute on a list of nested object' do
      subject {
        Class.new {
          extend Serialisable

          root 'items'
          elements :items, Class.new {
            extend Serialisable

            root 'item'
            attribute :id, 'id'
          }
        }
      }

      let(:xml) {
        '<?xml version="1.0" encoding="utf-8"?><items><item id="1234" /><item id="5678" /></items>'
      }

      it 'takes xml and returns an object with the attribute deserialised' do
        items = subject.deserialise(xml).items

        items[0].id.must_equal '1234'
        items[1].id.must_equal '5678'
      end
    end
  end

  describe 'all together' do
    let(:xml) {
      <<EOS
<?xml version="1.0" encoding="utf-8"?>
<plays>
  <play>
    <track>505</track>
    <artist>Arctic Monkeys</artist>
    <time>2013-10-12T15:34:50Z</time>
  </play>
  <play>
    <track>Windowlicker</track>
    <artist>Aphex Twin</artist>
    <time>2013-10-12T15:37:43Z</time>
  </play>
</plays>
EOS
    }

    subject {
      Class.new {
        extend Serialisable

        root 'plays'
        elements :plays, Class.new {
          extend Serialisable

          root 'play'
          element :track, 'track'
          element :artist, 'artist'
          element :time, 'time', Time
        }
      }
    }

    it 'works!' do
      plays = subject.deserialise(xml).plays

      plays[0].track.must_equal '505'
      plays[0].artist.must_equal 'Arctic Monkeys'
      plays[0].time.must_equal Time.utc(2013, 10, 12, 15, 34, 50)

      plays[1].track.must_equal 'Windowlicker'
      plays[1].artist.must_equal 'Aphex Twin'
      plays[1].time.must_equal Time.utc(2013, 10, 12, 15, 37, 43)
    end
  end
end
