require 'nokogiri'

module Serialisable
  def root(selector)
    @__root = selector
    @__elements = {}
  end

  def element(name, selector)
    @__elements[name] = selector
  end

  def deserialise(xml)
    doc = Nokogiri::XML(xml).children.find {|node| node.name == @__root }

    attrs = @__elements.map do |name, selector|
      value = doc.children.find {|node| node.name == 'node' }.children.to_s

      [name, value]
    end

    attrs = Hash[attrs]

    attrs.each do |key, value|
      define_method key do
        instance_variable_get(:@attrs)[key]
      end
    end

    obj = new
    obj.instance_variable_set(:@attrs, attrs)
    obj
  end
end
