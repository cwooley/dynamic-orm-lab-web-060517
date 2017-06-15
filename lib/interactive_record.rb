require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'


class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    # sql stuff dont ask me what pragma does, I just know that this gives
    # info on all of out columns.
    sql = "PRAGMA table_info('#{table_name}')"

    #giving us back a big, ugly hash
    table_info = DB[:conn].execute(sql)

    #We just want the names
    table_info.each_with_object([]) do |column, temp_arr|
      temp_arr << column["name"]
    end
  end

  def initialize(attributes_hash = {})
    #take each attribute pair and dynamically set them using send.
    attributes_hash.each do |attr_key, attr_val|
      self.send("#{attr_key}=", attr_val)
    end
  end

  def table_name_for_insert
    #just a helper to get to the table name from an instance
    self.class.table_name
  end

  def col_names_for_insert
    #Delete the ID column and join the rest into an SQL ready string.
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    #Get values for all atttributes dynamically by using send
    #Send them all into an array called values
    #Join them with a comma & space to make it an SQL ready string
    values = self.class.column_names.each_with_object([]) do |col_name, temp_arr|
      temp_arr << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def save
    #use helper methods to create an  SQL string
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    #execute sql
    DB[:conn].execute(sql)
    #get id back from DB and set our ID instance variable
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by(attr_hash)
    #sample attr_hash
    #{name: "Susan"}

    col_name = attr_hash.keys[0].to_s
    val = attr_hash.values[0].to_s

    # sql = "SELECT * FROM ? WHERE ? = ?"
    # DB[:conn].execute(sql, self.table_name, col_name, val)

    sql = "SELECT * FROM #{self.table_name} WHERE #{col_name} = '#{val}'"
    DB[:conn].execute(sql)
  end

  def self.find_by_name(name)
    # sql = "SELECT * FROM ? WHERE name = ?"
    # DB[:conn].execute(sql, self.table_name, name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end


end
