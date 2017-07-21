require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    col_names = []
    col_vals = []

    params.each do |k, v|
      col_names << k
      col_vals << v
    end

    where_str = []
    (0..col_names.length - 1).each do |i|
      where_str << "#{col_names[i]} = ?"
    end
    where_string = where_str.join(" AND ")  

    results = DBConnection.execute(<<-SQL, *col_vals )
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_string}
    SQL
    results.map { |result| self.new(result) }
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
