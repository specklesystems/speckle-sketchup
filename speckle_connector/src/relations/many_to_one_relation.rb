# frozen_string_literal: true

require_relative '../ext/immutable_ruby/core'

module SpeckleConnector
  module Relations
    # An immutable class that model a binary relation. It supports querying for both objects. For example
    # `A has child B` is Many to One relationship. Each person can have only one parent,
    # but one parent can have several children.
    class ManyToOneRelation
      attr_reader :parent_table
      attr_reader :children_table

      # @param child [Object] the child element in the relation to look for parent
      # @return [Object] the parent element that is in relation with the child
      # @return [nil] if the child element is not in the relation with any elements
      def find_parent(child)
        @parent_table[child]
      end

      # @param parent [Object] the parent element in the relation to look for children
      # @return [Immutable::Set] the children elements that are in relation with the parent element
      def find_children(parent)
        @children_table[parent] || Immutable::EmptySet
      end

      # Parents array.
      # @param child [Object] the child element in the relation to look for
      def parent_tree(child)
        tree = []
        current = child
        until @parent_table[current].nil?
          # Add parent to tree
          tree.append(@parent_table[current])
          # Change current with parent
          current = @parent_table[current]
        end
        tree
      end

      # Add another pair to the relation
      # @param child [Object] the child element in the relation
      # @param parent [Object] the parent element that is in the relation
      # @return [ManyToOneRelation] a new relation with added pair
      def add(child, parent)
        old_parent = @parent_table[child]
        return self if old_parent == parent

        # update lookup table for parent element in relation
        new_parent_by_child = @parent_table.put(child, parent)
        # update the lookup table for child elements in relation
        new_child_by_parent = add_to_children_table(child, parent)
        new_object = self.class.allocate
        new_object.instance_variable_set(:@children_table, new_child_by_parent)
        new_object.instance_variable_set(:@parent_table, new_parent_by_child)
        new_object.freeze
      end

      # Remove the child element from the relation
      # @param child [Object] the child element in the relation that needs to be removed from the relation
      # @return [ManyToOneRelation] new relation without the pair with the child element
      def delete(child)
        parent = @parent_table[child]
        return self unless parent

        new_parent_by_child = @parent_table.delete(child)
        new_child_by_parent = delete_child_from_children_table(child)
        new_object = self.class.allocate
        new_object.instance_variable_set(:@children_table, new_child_by_parent)
        new_object.instance_variable_set(:@parent_table, new_parent_by_child)
        new_object.freeze
      end

      # Remove all of the elements that are in relation with the given element
      # @param parent [Object] the parent element to be removed from the relation
      # @return [ManyToOneRelation] new relation without all the pair with the parent element
      def delete_parent(parent)
        children = find_children(parent)
        children.reduce(self) { |relation, child| relation.delete(child) }
      end

      def initialize(pairs = [])
        @parent_table = Immutable::Hash.new(pairs)
        groups = pairs.group_by { |_child, parent| parent }
        groups = groups.map do |parent, pairs_for_parent|
          children_for_parent = pairs_for_parent.map { |child, _parent| child }
          [parent, Immutable::Set.new(children_for_parent)]
        end
        @children_table = Immutable::Hash.new(groups)
      end

      private

      # Create updated parent table for child elements in the relation
      def add_to_children_table(child, parent)
        old_parent = @parent_table[child]
        old_children_for_old_parent = @children_table[old_parent] || Immutable::EmptySet
        new_children_for_old_parent = old_children_for_old_parent.delete(child)
        new_children_by_parent = if new_children_for_old_parent.empty?
                                   @children_table.delete(old_parent)
                                 else
                                   @children_table.put(old_parent, new_children_for_old_parent)
                                 end
        new_children_for_parent = @children_table[parent] || Immutable::EmptySet
        new_children_by_parent.put(parent, new_children_for_parent.add(child))
      end

      # Create updated children table for children elements in the relation
      def delete_child_from_children_table(child)
        parent = @parent_table[child]
        # delete child element in relation from the element set for parent element
        old_children_for_parent = @children_table[parent]
        new_children_for_parent = old_children_for_parent.delete(child)
        if new_children_for_parent.empty?
          @children_table.delete(parent)
        else
          @children_table.put(parent, new_children_for_parent)
        end
      end
    end

    # An empty many to one relation
    EMPTY_MANY_TO_ONE_RELATION = ManyToOneRelation.new
  end
end
