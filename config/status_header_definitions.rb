# frozen_string_literal: true

module Crossbeams
  module Config
    # Store rules for displaying header information for a record from a table.
    #
    # The Hash key is the table name as a Symbol.
    # query: is the query to run with a '?' placehoder for the id value.
    # headers: is a hash of column_name to String values for overriding the column name.
    # caption: is an optional caption for the record.
    class StatusHeaderDefinitions
      HEADER_DEF = {
        labels: {
          query: 'SELECT label_name, created_by FROM labels WHERE id = ?'
        },
        security_groups: {
          query: 'SELECT security_group_name FROM security_groups WHERE id = ?'
        }
      }.freeze
    end
  end
end
