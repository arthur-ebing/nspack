# frozen_string_literal: true

module EdiApp
  class XmlFileRepo
    include Crossbeams::Responses

    attr_accessor :schema, :record_definitions, :rec_type_lookup, :flow_type, :toc

    def initialize(flow_type)
      @flow_type = flow_type
    end

    def validate_xml_schema(file_path) # rubocop:disable Metrics/AbcSize
      schema_file = File.expand_path("../schemas/#{flow_type.downcase}.xsd", __dir__)
      raise "There is no XSD schema for EDI flow type #{flow_type}" unless File.exist?(schema_file)

      xsd = Nokogiri::XML::Schema(File.read(schema_file))
      doc = Nokogiri::XML(File.read(file_path))
      result = xsd.validate(doc) # .each { |error| puts error.message }
      if result.empty?
        ok_response
      else
        failed_response('invalid schema', result)
      end
    end

    def records_from_file(file_path)
      parse_opt = Nokogiri::XML::ParseOptions.new.noblanks
      doc = Nokogiri::XML(File.read(file_path), nil, nil, parse_opt)

      { doc.root.name => unpack_node(doc.root) }
    end

    private

    def unpack_node(node) # rubocop:disable Metrics/AbcSize
      return node.text if node.text?

      names = node.children.map(&:name)
      if names.uniq.length < names.length # Array
        node.children.map { |n| { n.name => unpack_node(n) } }
      elsif node.children.length == 1 && node.children.first.name == 'text'
        node.children.first.text
      else
        nh = {}
        node.children.each do |cn|
          nh[cn.name] = unpack_node(cn)
        end
        nh.empty? ? nil : nh
      end
    end
  end
end
