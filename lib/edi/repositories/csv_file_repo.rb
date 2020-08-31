# frozen_string_literal: true

module EdiApp
  class CsvFileRepo
    include Crossbeams::Responses

    attr_accessor :schema, :flow_type

    def initialize(flow_type)
      @flow_type = flow_type
    end

    def validate_csv_schema(file_path) # rubocop:disable Metrics/AbcSize
      schema_file = File.expand_path("../schemas/#{flow_type.downcase}.yml", __dir__)
      raise "There is no YML schema for EDI flow type #{flow_type}" unless File.exist?(schema_file)

      schema = YAML.load_file(schema_file)
      required_keys = schema.keys.map(&:to_s)
      header = File.foreach(file_path).first.chomp.split(',')
      result = required_keys - header

      if result.empty?
        ok_response
      else
        failed_response('missing headers', result)
      end
    end

    def records_from_file(file_path)
      recs = CSV.read(file_path, headers: true)
      recs.map { |r| Hash[r.to_a] }
    end
  end
end
