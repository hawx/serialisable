require 'nokogiri'

module Serialisable
  def root(selector)
    @__root = selector
    @__element = {}
    @__elements = {}
  end

  def element(name, selector, type=String)
    @__element[name] = [selector, type]
  end

  def elements(name, klass)
    @__elements[name] = [klass]
  end

  def deserialise(xml)
    __deserialise Nokogiri::XML(xml)
  end

  private

  def __deserialise_all(doc)
    doc = doc.children.find_all {|node| node.name == @__root }

    attrs_list = doc.map do |node|
      @__element.map do |name, (selector, type)|
        value = node.children.find {|node| node.name == selector }.children.to_s

        if type.respond_to?(:parse)
          value = type.parse(value)
        end

        [name, value]
      end
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

    attrs = @__elements.map do |name, (klass)|
      [name, klass.send(:__deserialise_all, doc)]
    end

    attrs += @__element.map do |name, (selector, type)|
      if selector.respond_to?(:__deserialise, true)
        [name, selector.send(:__deserialise, doc)]
      else
        value = doc.children.find {|node| node.name == selector }.children.to_s

        if type.respond_to?(:parse)
          value = type.parse(value)
        end

        [name, value]
      end
    end

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
