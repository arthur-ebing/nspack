# frozen_string_literal: true

require File.join(File.expand_path('./../', __FILE__), 'test_helper')

class TestGridQueries < MiniTestWithHooks
  def load_all_queries
    # load report hashes & store column names
    @query_columns = {}
    queries = Dir.glob('grid_definitions/dataminer_queries/*.yml')
    queries.each do |file|
      hash = YAML.load(File.read(file))
      params = hash[:query_parameter_definitions]
      if params.nil? || params.empty?
        @query_columns[File.basename(file).sub(File.extname(file), '')] = []
      else
        @query_columns[File.basename(file).sub(File.extname(file), '')] = params.map { |c| c[:column] }
      end
    end
  end

  # Check that list yml definitions do not reference invalid query parameter names
  def test_list_grids
    load_all_queries
    errs = []
    lists = Dir.glob('grid_definitions/lists/*.yml')
    lists.each do |file|
      hash = YAML.load(File.read(file))

      conditions = hash[:conditions]
      query = hash[:dataminer_definition]
      assert @query_columns[query], %(List grid: "#{File.basename(file).sub(File.extname(file), '')}" references non-existent query "#{query}")
      client_queries = if hash[:dataminer_client_definitions]
                         hash[:dataminer_client_definitions].to_a
                       else
                         []
                       end
      client_queries.each do |client, qry|
        assert @query_columns[qry], %(List grid: "#{File.basename(file).sub(File.extname(file), '')}" references non-existent query "#{qry}" for client "#{client}")
      end

      conditions&.each do |key, options|
        options.each do |opt|
          unless @query_columns[query].include?(opt[:col])
            errs << %(List: "#{File.basename(file).sub(File.extname(file), '')}", condition: "#{key}" - col: "#{opt[:col]}" is not in query "#{query}")
          end
          client_queries.each do |client, qry|
            unless @query_columns[qry].include?(opt[:col])
              errs << %(List: "#{File.basename(file).sub(File.extname(file), '')}", condition: "#{key}" - col: "#{opt[:col]}" is not in query "#{qry}")
            end
          end
        end
      end
    end

    if errs.empty?
      assert true
    else
      assert false, "\n--------\nList yml files with invalid column names for conditions:\n--------\n#{errs.join("\n")}"
    end
  end

  # Check that lookup yml definitions do not reference invalid query parameter names
  def test_lookup_grids
    load_all_queries
    errs = []
    lists = Dir.glob('grid_definitions/lookups/*.yml')
    lists.each do |file|
      hash = YAML.load(File.read(file))

      conditions = hash[:conditions]
      query = hash[:dataminer_definition]
      assert @query_columns[query], %(Lookup grid: "#{File.basename(file).sub(File.extname(file), '')}" references non-existent query "#{query}")

      conditions&.each do |key, options|
        options.each do |opt|
          unless @query_columns[query].include?(opt[:col])
            errs << %(Lookup: "#{File.basename(file).sub(File.extname(file), '')}", condition: "#{key}" - col: "#{opt[:col]}" is not in query "#{query}")
          end
        end
      end
    end

    if errs.empty?
      assert true
    else
      assert false, "\n----------\nLookup yml files with invalid column names for conditions:\n----------\n#{errs.join("\n")}"
    end
  end
end
