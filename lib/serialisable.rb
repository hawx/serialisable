require 'nokogiri'

module Serialisable
  def root(selector)
    @__root = selector
    @__element = {}
    @__elements = {}
    @__attribute = {}
  end

  def attribute(name, selector, type=String)
    @__attribute[name] = [selector, type]
  end

  def element(name, selector, type=String)
    @__element[name] = [selector, type]
  end

  def elements(name, *args)
    case args.size
    when 1
      klass = args.first
      @__elements[name] = [nil, klass]
    when 2
      selector, type = args
      @__elements[name] = [selector, type]
    else
      raise ArgumentError
    end
  end

  def deserialise(xml)
    __deserialise Nokogiri::XML(xml)
  end

  private

  def __deserialise_all(doc)
    doc = doc.children.find_all {|node| node.name == @__root }

    attrs_list = doc.map do |node|
      attrs = SerialisableHelpers.get_multiples(node, @__elements)
      attrs += SerialisableHelpers.get_singles(node, @__element)
      attrs += SerialisableHelpers.get_attributes(node, @__attribute)

      attrs
    end

    objs = []
    attrs_list.each do |attrs|
      attrs = Hash[attrs]

      attrs.each do |key, value|
        define_method key do
          instance_variable_get(:@__serialisable_attrs)[key]
        end
      end

      obj = new
      obj.instance_variable_set(:@__serialisable_attrs, attrs)
      objs << obj
    end

    objs
  end

  def __deserialise(doc)
    doc = doc.children.find {|node| node.name == @__root }

    attrs = SerialisableHelpers.get_multiples(doc, @__elements)
    attrs += SerialisableHelpers.get_singles(doc, @__element)
    attrs += SerialisableHelpers.get_attributes(doc, @__attribute)

    attrs = Hash[attrs]

    attrs.each do |key, value|
      define_method key do
        instance_variable_get(:@__serialisable_attrs)[key]
      end
    end

    obj = new
    obj.instance_variable_set(:@__serialisable_attrs, attrs)
    obj
  end
end

module SerialisableHelpers
  extend self

  def get_multiples(root, hash)
    hash.map do |name, (selector, type)|
      if type.respond_to?(:__deserialise_all, true)
        [name, type.send(:__deserialise_all, root)]
      else
        values = root.children.find_all {|node| node.name == selector }
          .map {|node| node.children.to_s }
          .map {|value| parse_type(value, type) }

        [name, values]
      end
    end
  end

  def get_singles(root, hash)
    hash.map do |name, (selector, type)|
      if selector.respond_to?(:__deserialise, true)
        [name, selector.send(:__deserialise, root)]
      else
        value = root.children.find {|node| node.name == selector }.children.to_s
        value = parse_type(value, type)

        [name, value]
      end
    end
  end

  def get_attributes(root, hash)
    hash.map do |name, (selector, type)|
      value = root.attributes[selector].value
      value = parse_type(value, type)

      [name, value]
    end
  end

  # Parses the value read from xml if the type given responds to the method
  # #parse, otherwise returns the string value.
  #
  # @param value [String]
  # @param type [#parse]
  def parse_type(value, type)
    type.respond_to?(:parse) ? type.parse(value) : value
  end
end
