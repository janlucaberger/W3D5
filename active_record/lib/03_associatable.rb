require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'
# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    # debugger
    @class_name.to_s.constantize
  end

  def table_name
    @class_name.downcase.underscore + "s"
  end
end


class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || (name.to_s + "_id").to_sym
    @class_name = options[:class_name] || name.to_s.camelcase
    @primary_key = options[:primary_key] || :id
  end
end


class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || (self_class_name.downcase.to_s + "_id").to_sym
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    parent = BelongsToOptions.new(name, options)
    self.assoc_options[name] = parent

    define_method(name) do
      options = self.class.assoc_options[name]

      foreign_key = options.foreign_key
      primary_key = options.primary_key
      model_class = options.class_name.constantize

      result = model_class.where("#{primary_key}" => self.attributes[foreign_key])
      result.first
    end

  end

  def has_many(name, options = {})
    define_method(name) do
      children = HasManyOptions.new(name, self.class.to_s, options)
      foreign_key = children.send(:foreign_key)
      primary_key = children.send(:primary_key)
      model_class = children.model_class

      results = model_class.where("#{foreign_key}" => self.attributes[primary_key])
      results
    end
  end

  def assoc_options
    @@assoc_options ||= {}
    # debugger
    # @@assoc_options[self.to_s.downcase.to_sym]
  end
end



class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
