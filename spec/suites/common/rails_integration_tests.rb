require File.expand_path('../adapter_integration_tests', __FILE__)
require File.expand_path('../../../adapter_integration_tests/rails_project', __FILE__)

module RailsIntegrationTests
  class ChangeDatabaseTableMatcher < Struct.new(:project, :table_name)
    def description
      "change the database table #{table_name}"
    end

    def matches?(block)
      return_value = true
      return_value &&= table_has_no_rows?
      block.call
      return_value &&= table_has_no_rows?
      return_value
    end

    def table_has_no_rows?
      @number_of_rows = `echo "select count(*) from #{project.table_name};" | sqlite3 #{project.sqlite_db_file_path}`.chomp
      @number_of_rows.to_i == 0
    end

    def failure_message_for_should
      raise "You should call this with should_not"
    end

    def failure_messsage_for_should_not
      "Expected for database table #{table_name} to not have been changed, but it was (number of rows: #{@number_of_rows})"
    end
  end

  include AdapterIntegrationTests

  #def build_project
  #  AdapterIntegrationTests::RailsProject.new
  #end

  def change_database_table(table_name)
    ChangeDatabaseTableMatcher.new(table_name)
  end
end
