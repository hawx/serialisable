require 'nokogiri'
require_relative 'serialisable/selector'

module Serialisable
  def root(selector)
    @__root = selector
    @__selectors = []
  end

  def attribute(name, selector, type = nil)
    @__selectors << Selector::Attribute.new(name, selector, type)
  end

  def element(name, selector, type = nil)
    if selector.respond_to?(:__deserialise, true)
      @__selectors << Selector::Nested.new(name, selector, type)
    else
      @__selectors << Selector::Node.new(name, selector, type)
    end
  end

  def elements(name, *args)
    case args.size
    when 1
      klass = args.first
      @__selectors << Selector::NestedMultiple.new(name, klass)
    when 2
      selector, type = args
      @__selectors << Selector::Nodes.new(name, selector, type)
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

    doc.map {|node| __select(node) }
  end

  def __deserialise(doc)
    node = doc.children.find {|node| node.name == @__root }

    __select(node)
  end

  def __select(node)
    new.tap {|obj|
      @__selectors.each {|selector|
        obj.singleton_class.send(:define_method, selector.name) {
          selector.match(node)
        }
      }
    }
  end
end
