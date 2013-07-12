require File.expand_path('../adapter_integration_tests', __FILE__)
require File.expand_path('../rails_project', __FILE__)
require File.expand_path('../project_creator', __FILE__)

module RailsIntegrationTests
  class LeaveDatabaseTableClearMatcher < Struct.new(:project, :table_name)
    def matches?(block)
      @old_number_of_rows = number_of_rows
      block.call
      @new_number_of_rows = number_of_rows
      @old_number_of_rows == 0 && @new_number_of_rows == 0
    end

    def description
      "leave the database table #{table_name} unchanged"
    end

    def failure_message_for_should
      "Expected for database table #{table_name} to have been left clear, but it was changed (there are now #{@new_number_of_rows} rows)"
    end

    def failure_message_for_should_not
      "Expected for database table #{table_name} to not have been left clear, but it was"
    end

    private

    def number_of_rows
      `echo "select count(*) from #{table_name};" | sqlite3 #{project.database_file_path}`.chomp.to_i
    end
  end

  include AdapterIntegrationTests

  def configure_project_creator(creator)
    super
    creator.add RailsProject
  end

  def leave_database_table_clear(project, table_name)
    LeaveDatabaseTableClearMatcher.new(project, table_name)
  end
end
