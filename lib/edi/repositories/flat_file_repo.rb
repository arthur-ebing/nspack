# frozen_string_literal: true

module EdiApp
  class FlatFileRepo # rubocop:disable Metrics/ClassLength
    attr_accessor :schema, :record_definitions, :rec_type_lookup, :flow_type, :toc

    def initialize(flow_type)
      @flow_type = flow_type
      @field_defs = {}
      @record_definitions = Hash.new { |h, k| h[k] = {} } # Hash.new { |h, k| h[k] = [] }
      @rec_type_lookup = {}
      field_definitions
    end

    # Convert the file into an array of records (one per line).
    #
    # @param file_name [string] the name of the file to convert.
    # @param fix_encoding [boolean] fix encoding errors. Default is true.
    # @return [array] an array of hashes containing key/value records.
    def records_from_file(file_name, fix_encoding: true)
      @out = []
      File.foreach(file_name) do |line|
        # Any invalid or undefined characters are replaced with a space before any processing is done:
        # Typically invalid characters have been set to "\xA0" (a non-breaking space), so to convert to
        # an ascii space seems to be the best option because:
        # - this is most probably what the character is supposed to represent.
        # - the affected fields will still be the same length after encoding.
        encoded_line = if fix_encoding
                         line.ascii_only? ? line : line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ' ')
                       else
                         line
                       end
        rules = find_rule(encoded_line)
        @out << build_out(rules, encoded_line)
      end
      @out
    end

    # Build records from the file, but do not fix encoding errors.
    # Prints a list of the keys/values which have invalid characters.
    def list_invalid_encoding_fields(file_name)
      records_from_file(file_name, fix_encoding: false)
      @out.each do |rec|
        rec.each do |r|
          p r unless r.last.nil? || r.last.ascii_only?
        end
      end
    end

    def table_of_contents
      rec_seq = @out.map { |m| m[:record_type] || m[:header] }
      @toc = []
      rec_seq.each_with_index do |a, i|
        @toc << a if a != rec_seq[i - 1]
      end
    end

    def grid_cols_and_rows # rubocop:disable Metrics/AbcSize
      table_of_contents
      grids = []
      cnt = -1
      curr = nil
      key = nil
      @out.each do |rec|
        if curr != (rec[:record_type] || rec[:header])
          curr = (rec[:record_type] || rec[:header])
          cnt += 1
          key = "#{toc[cnt]}-#{cnt}"
          coldef = coldef_for(curr) # Get from definition doesnt work for OL-2... LF/LT == OL...
          grids << { key => { cols: coldef, rows: [] } }
        end
        grids.last[key][:rows] << rec
      end
      grids
      # start at toc[0], with cnt = 0
      # for each out
      # if header/rectype <> toc[cnt], cnt += 1 and grids[toc[cnt]-cnt] = []
      # add col def for toc[cnt] as well
      # append row to array

      # return:
      # grids = { BH: { cols: [], rows: [] },
      #         _ PS: { cols: [], rows: [] },
      #         _ BT: { cols: [], rows: [] }
      #         }
      # (what to do when row has sub-rows and then the whole set repeats a few times..
      # Page to render as many grids as keys in the hash...
    rescue StandardError => e
      p grids
      raise e
    end

    private

    def coldef_for(key)
      record_definitions[key].map { |_, v| { headerName: v[:name], field: v[:name] } }
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
        # if field_name['name'].to_s == 'record_type' && default != key
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

    def find_rule(line)
      rec_type = line[0, 2]
      key = rec_type_lookup[rec_type]
      record_definitions[key]
    end

    def build_out(rules, line)
      rec = {}
      rules.each do |field_name, rule|
        val = line[rule.offset, rule.length]&.strip
        rec[field_name] = val.nil_or_empty? ? nil : val # ensure_ascii(val)
      end
      rec
    end
  end
end
