# frozen_string_literal: true

module EdiApp
  class FlatFileRepo
    attr_accessor :schema, :record_definitions, :rec_type_lookup, :flow_type

    def initialize(flow_type)
      @flow_type = flow_type
      @field_defs = {}
      @record_definitions = Hash.new { |h, k| h[k] = {} } # Hash.new { |h, k| h[k] = [] }
      @rec_type_lookup = {}
      field_definitions
    end

    def field_definitions
      file_path = File.expand_path("../schemas/#{flow_type.downcase}.xml", __dir__)
      raise "There is no XML schema for EDI flow type #{flow_type}" unless File.exist?(file_path)

      @schema = Nokogiri::XML(File.read(file_path))
      record_keys = schema.xpath('.//record/@identifier').map(&:value)
      record_keys.each { |key| build_field_definitions(key) }
    end

    def build_field_definitions(key) # rubocop:disable Metrics/AbcSize
      field_nodes = schema.xpath(".//record[@identifier='#{key}']/fields/field")
      offset = 0
      this_key = nil
      field_nodes.each do |field_node|
        len = field_node['size'].to_i
        rec = OpenStruct.new(name: field_node['name'].to_s.to_sym,
                             offset: offset,
                             length: len,
                             required: field_node['required'] == 'true',
                             trim: field_node['trim'] == 'true',
                             format: field_node['format'])
        rec[:default] = field_node.attributes['default'].to_s if field_node.attributes['default']
        raise "There is already a rule for #{field_node['name']} in #{flow_type.downcase}.xml for #{key}. Please make it unique" unless record_definitions[key][field_node['name'].to_s.to_sym].nil?

        record_definitions[key][field_node['name'].to_s.to_sym] = rec
        offset += len

        this_key = rec.default if %i[header record_type trailer].include?(rec.name)
      end
      rec_type_lookup[this_key] = key
    end

    def records_from_file(file_name)
      out = []
      File.foreach(file_name) do |line|
        rules = find_rule(line)
        out << build_out(rules, line)
      end
      out
    end

    def find_rule(line)
      rec_type = line[0, 2]
      key = rec_type_lookup[rec_type]
      record_definitions[key]
    end

    def build_out(rules, line)
      rec = {}
      rules.each do |field_name, rule|
        val = line[rule.offset, rule.length].strip
        rec[field_name] = val.empty? ? nil : val
      end
      rec
    end

    def grid_cols_and_rows
      # return:
      # grids = { BH: { cols: [], rows: [] },
      #         _ PS: { cols: [], rows: [] },
      #         _ BT: { cols: [], rows: [] }
      #         }
      # (what to do when row has sub-rows and then the whole set repeats a few times..
      # Page to render as many grids as keys in the hash...
    end
  end
end
