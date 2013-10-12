# Serialisable

Simple xml to object deserialisation for Ruby, built on top of Nokogiri (at the
moment).

This is still in the hacky stage, so you probably shouldn't use it...

``` xml
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
```

``` ruby
require 'serialisable'
require 'time'

class Play
  extend Serialisable

  root 'play'
  element :track, 'track'
  element :artist, 'artist'
  element :time, 'time', Time   # an object responding to #parse
end

class Plays
  extend Serialisable

  root 'plays'
  elements :plays, Play         # a Serialisable object
end

plays = Plays.deserialise(File.read('plays.xml')).plays
```
