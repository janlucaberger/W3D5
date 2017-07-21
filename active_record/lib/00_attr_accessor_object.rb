require 'byebug'

class AttrAccessorObject
  def self.my_attr_accessor(*names)
    puts names
    names.each do |name|
      attr_get = name
      attr_set = (name.to_s + "=").to_sym

      define_method(attr_set) do |val|
        self.instance_variable_set("@#{name}", val)
      end

      define_method(attr_get) { self.instance_variable_get("@#{name}") }
    end
  end
end
