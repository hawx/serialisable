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

  describe 'with a list of elements to parse' do

    subject {
      require 'time'

      Class.new {
        extend Serialisable

        root 'root'
        elements :times, 'time', Time
      }
    }

    let (:xml) {
      <<EOS
<?xml version="1.0" encoding="utf-8"?>
<root>
  <time>2013-05-06T00:00:00Z</time>
  <time>2013-06-07T00:00:00Z</time>
</root>
EOS
    }

    it 'takes xml and returns an object, with types parsed' do
      times = subject.deserialise(xml).times
      times.must_equal [Time.utc(2013, 5, 6), Time.utc(2013, 6, 7)]
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

  describe '#elements' do
    it 'raises an exception if not given less than two arguments' do
      lambda {
        Class.new {
          extend Serialisable

          elements :name
        }
      }.must_raise ArgumentError
    end

    it 'raises an exception if given more than three arguments' do
      lambda {
        Class.new {
          extend Serialisable

          elements :name, 'one', 'two', 'three'
        }
      }.must_raise ArgumentError
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
