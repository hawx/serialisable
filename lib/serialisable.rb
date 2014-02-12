require 'nokogiri'
require_relative 'serialisable/selector'

# Serialisable allows you to easily define an object that can deserialise xml
# into instances of itself. It provides a simple but powerful DSL for defining
# elements and attributes.
#
#   require 'serialisable'
#   require 'time'
#
#   class Play
#     extend Serialisable
#
#     root 'play'
#     element :artist, 'artist'
#     element :name, 'name'
#     element :played_at, 'playedat', Time
#   end
#
#   class User
#     extend Serialisable
#
#     root 'user'
#     attribute :id, 'id', :to_i
#     element   :name, 'name'
#     elements  :plays, 'plays', Play
#
#     def inspect
#       "#<User:#{id} #{name}>"
#     end
#   end
#
#   user = User.deserialise <<XML
#   <?xml version="1.0" encoding="utf-8"?>
#   <user id="12452">
#     <name>John Doe</name>
#     <plays>
#       <play>
#         <artist>Arctic Monkeys</artist>
#         <name>505</name>
#         <playedat>2014-02-03T12:23:55Z</playedat>
#       </play>
#       <play>
#         <artist>Aphex Twin</artist>
#         <name>Windowlicker</name>
#         <playedat>2014-02-03T12:26:13Z</playedat>
#       </play>
#     </plays>
#   </user>
#   XML
#
#   p user
#   #=> #<User:12452 John Doe>
#   p user.plays.map(&:name)
#   #=> ["505", "Windowlicker"]
#
#
# @example Type as Symbol
#
#   class Count
#     extend Serialisable
#
#     root 'count'
#     attribute :value, 'value', :to_i
#   end
#
#   count = Count.deserialise <<XML
#   <?xml version="1.0" encoding="utf-8"?>
#   <count value="500" />
#   XML
#
#   p count.value #=> 500
#
#
# @example Type as object responding to +#parse+
#
#   class IntParser
#     def parse(str); str.to_i; end
#   end
#
#   class Count
#     extend Serialisable
#
#     root 'count'
#     attribute :value, 'value', IntParser
#   end
#
#   count = Count.deserialise <<XML
#   <?xml version="1.0" encoding="utf-8"?>
#   <count value="500" />
#   XML
#
#   p count.value #=> 500
#
#
module Serialisable
  def self.extended(obj)
    obj.instance_variable_set(:@__selectors, [])
  end

  # Define the element that makes up the root for the class.
  #
  # @param selector [String] Name of xml element to mark as the root.
  def root(selector)
    @__root = selector
  end

  # Define an attribute selector. This will match an attribute in the defined
  # root element that has the name given by +selector+.
  #
  # @param name [Symbol] Name of the method to be defined on the class that
  #   returns the value matched.
  # @param selector [String] Name of xml attribute to match against.
  # @param type [Symbol, #parse] If a symbol is given the matched string will
  #   have the method named by it called on it. If an object responding to
  #   #parse is given then the string value will be passed to that method.
  def attribute(name, selector, type = nil)
    @__selectors << Selector::Attribute.new(name, selector, type)
  end

  # Define an element selector. This will match a node in the defined root
  # element that has the name given by +selector+.
  #
  # @overload element(name, serialisable)
  #   Use this when the node being matched contains nested xml.
  #
  #   @param name [Symbol] Name of the method to be defined on the class that
  #     returns the value matched.
  #   @param serialisable [Serialisable]
  #
  # @overload element(name, root, serialisable)
  #   Use this when the node being matched contains nested xml and the root
  #   needs to be set.
  #
  #   @param name [Symbol] Name of the method to be defined on the class that
  #     returns the value matched.
  #   @param root [String] Name of the root of the nested element, this
  #     overrides any root set on the +serialisable+ passed.
  #   @param serialisable [Serialisable] Serialisable object that represents
  #     the nested element.
  #
  # @overload element(name, selector, type=nil)
  #   Use this when the node only contains text.
  #
  #   @param name [Symbol] Name of the method to be defined on the class that
  #     returns the value matched.
  #   @param selector [String] Name of xml attribute to match against.
  #   @param type [Symbol, #parse] If a symbol is given the matched string will
  #     have the method named by it called on it. If an object responding to
  #     #parse is given then the string value will be passed to that method.
  #
  def element(name, selector, type = nil)
    if selector.respond_to?(:__deserialise, true)
      @__selectors << Selector::Nested.new(name, selector)

    elsif type.respond_to?(:__deserialise, true)
      cloned_type = type.clone
      cloned_type.instance_variable_set(:@__root, selector)
      @__selectors << Selector::Nested.new(name, cloned_type)

    else
      @__selectors << Selector::Node.new(name, selector, type)
    end
  end

  # Define an elements selector. This will match all nodes in the defined root
  # element that has the name given by +selector+. The method created by this
  # will return an array of matching values.
  #
  # @overload elements(name, serialisable)
  #   Use this when the nodes being matched contains nested xml.
  #
  #   @param name [Symbol] Name of the method to be defined on the class that
  #     returns the value matched.
  #   @param serialisable [Serialisable]
  #
  # @overload elements(name, root, serialisable)
  #   Use this when the nodes being matched contains nested xml and the root
  #   needs to be set.
  #
  #   @param name [Symbol] Name of the method to be defined on the class that
  #     returns the value matched.
  #   @param root [String] Name of the root of the nested element, this
  #     overrides any root set on the +serialisable+ passed.
  #   @param serialisable [Serialisable] Serialisable object that represents
  #     the nested element.
  #
  # @overload elements(name, selector, type=nil)
  #   Use this when the nodes only contain text.
  #
  #   @param name [Symbol] Name of the method to be defined on the class that
  #     returns the value matched.
  #   @param selector [String] Name of xml attribute to match against.
  #   @param type [Symbol, #parse] If a symbol is given the matched string will
  #     have the method named by it called on it. If an object responding to
  #     #parse is given then the string value will be passed to that method.
  #
  def elements(name, selector, type = nil)
    if selector.respond_to?(:__deserialise_all, true)
      @__selectors << Selector::NestedMultiple.new(name, selector, type)

    elsif type.respond_to?(:__deserialise_all, true)
      cloned_type = type.clone
      cloned_type.instance_variable_set(:@__root, selector)
      @__selectors << Selector::NestedMultiple.new(name, cloned_type)

    else
      @__selectors << Selector::Nodes.new(name, selector, type)
    end
  end

  # Deserialises the given +xml+ into an instance of the class.
  #
  # @param xml [String]
  # @return An instance of the class that the method was called on.
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
