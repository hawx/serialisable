module Serialisable

  # @abstract Must implement #match
  class Selector
    attr_reader :name

    def initialize(name, selector, type = nil)
      @name = name
      @selector = selector
      @type = type
    end

    def parse(value)
      if @type.respond_to?(:parse)
        @type.parse(value)
      elsif @type.is_a?(Symbol)
        value.send(@type)
      else
        value
      end
    end

    class Attribute < Selector
      def match(root)
        parse root.attributes[@selector].value
      end
    end

    class Node < Selector
      def match(root)
        parse root.children
          .find {|node| node.name == @selector }
          .children.to_s
      end
    end

    class Nodes < Selector
      def match(root)
        root.children
          .find_all {|node| node.name == @selector }
          .map {|node| parse node.children.to_s }
      end
    end

    class Nested < Selector
      def match(root)
        @selector.send(:__deserialise, root)
      end
    end

    class NestedMultiple < Selector
      def match(root)
        @selector.send(:__deserialise_all, root)
      end
    end
  end
end
