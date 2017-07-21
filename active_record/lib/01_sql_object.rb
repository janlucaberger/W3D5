require_relative 'db_connection'
# require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject


  def self.columns
    @columns || (
    results = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @columns = results[0].map {|clm| clm.to_sym }
    )
  end

  def self.finalize!
    columns.each do |column|
      col_get = column
      col_set = (column.to_s + "=").to_sym

      define_method(col_get) do
        self.attributes[column]
      end

      define_method(col_set) do |val|
        self.attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    tableized = (self.to_s).downcase + "s"
    @table_name || @table_name = tableized
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    objects = []
    results.each do |result|
      objects << self.new(result)
    end
    objects
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
       id = ?
    SQL

    self.parse_all(result).first
  end

  def initialize(params = {})
    columns = self.class::columns
    params.each do |k, v|
      raise "unknown attribute '#{k}'" unless columns.include?(k.to_sym)
      self.send("#{k}=", v)
    end
  end

  def attributes
    if defined?(@attributes).nil?
      instance_variable_set("@attributes", {})
    end
    @attributes
  end

  def attribute_values
    # ...
  end

  def insert
    column_names  = self.class.columns.drop(1).map { |c| c.to_s }.join(", ")
    question_marks = (["?"] * (self.class.columns.length - 1)).join(", ")

    columns_string = "(#{column_names})"
    val_string = "(#{question_marks})"

    values = @attributes.values

    DBConnection.execute(<<-SQL, *values)
      INSERT INTO
        #{self.class.table_name} #{columns_string}
      VALUES
        #{val_string}
    SQL

    @attributes[:id] = DBConnection.last_insert_row_id
  end

  def update

    # Puts the names and values into arrays that are ordered by KEY
    # and VALUE with respect to their index positions
    col_names = []
    col_vals = []
    @attributes.each do |attrib, value|
      col_names << attrib
      col_vals << value
    end

    # rotate arrays so the ID is the last value in both name and values
    # so that it will get populated last in the update
    col_vals.rotate!
    col_names.rotate!

    set_str = []
    (0...self.class.columns.length - 1).each do |i|
      set_str << "#{col_names[i]} = ?"
    end
    set_strings = set_str.join(", ")

    DBConnection.execute(<<-SQL, *col_vals)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_strings}
      WHERE
        id = ?
    SQL

  end

  def save
    self.attributes[:id].nil? ? self.insert : self.update
  end
end
