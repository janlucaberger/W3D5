require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      thru_class = through_options.class_name.constantize
      thru_primary = through_options.primary_key
      thru_foreign = through_options.foreign_key
      thru_model = thru_class.where("#{thru_primary}" => self.attributes[thru_foreign])

      source_class = source_options.class_name.constantize
      source_fkey = source_options.foreign_key
      join_key = thru_model.first.attributes[source_fkey]


      result = source_class.where(id: join_key )
      result.first
    end
  end
end
