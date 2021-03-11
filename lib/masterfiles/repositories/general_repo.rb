# frozen_string_literal: true

module MasterfilesApp
  class GeneralRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :uom_types,
                     label: :code,
                     value: :id,
                     order_by: :code
    build_inactive_select :uom_types,
                          label: :code,
                          value: :id,
                          order_by: :code
    crud_calls_for :uom_types,
                   name: :uom_type,
                   wrapper: UomType

    build_inactive_select :uoms,
                          label: :uom_code,
                          value: :id,
                          order_by: :uom_code
    crud_calls_for :uoms, name: :uom

    crud_calls_for :masterfile_variants, name: :masterfile_variant

    crud_calls_for :external_masterfile_mappings, name: :external_masterfile_mapping

    def for_select_uoms(where: {}, exclude: {}, active: true)
      DB[:uoms]
        .join(:uom_types, id: :uom_type_id)
        .where(Sequel[:uoms][:active] => active)
        .where(where)
        .exclude(exclude)
        .select_map([:uom_code, Sequel[:uoms][:id]])
    end

    def find_uom(id)
      find_with_association(:uoms, id,
                            parent_tables: [{ parent_table: :uom_types,
                                              flatten_columns: { code: :uom_type_code } }],
                            wrapper: MasterfilesApp::Uom)
    end

    def default_uom_type_id
      DB[:uom_types].where(code: AppConst::UOM_TYPE).get(:id)
    end

    def find_masterfile_variant(id)
      hash = find_hash(:masterfile_variants, id)
      return nil if hash.nil?

      variant = lookup_mf_variant(hash[:masterfile_table])
      hash[:variant] = variant[:variant]
      hash[:masterfile_column] = variant[:column_name]
      hash[:masterfile_code] = get(hash[:masterfile_table].to_sym, hash[:masterfile_id], hash[:masterfile_column].to_sym)

      MasterfileVariant.new(hash)
    end

    def for_select_mf_variant
      array = []
      AppConst::MF_VARIANT_RULES.each do |variant, hash|
        array << [variant.to_s.gsub('_', ' '), hash[:table_name]]
      end
      array
    end

    def lookup_mf_variant(table_name)
      return {} if table_name.to_s.nil_or_empty?

      variant = AppConst::MF_VARIANT_RULES.select { |_, hash| hash.key(table_name.to_s) }
      return {} if variant.values.empty?

      { variant: variant.keys.first.to_s.gsub('_', ' '),
        table_name: table_name,
        column_name: variant.values.first[:column_name] }
    end

    # Gets the id or variant id from a record matching the args
    #
    # @param table_name [Symbol] the db table name.
    # @param args [Hash] the where-clause conditions.
    # @return [integer] the id value for the matching record or nil.
    def get_variant_id(table_name, args)
      id = get_id(table_name, args)
      return id unless id.nil?

      variant_code = args.delete(lookup_mf_variant(table_name)[:column_name].to_sym)
      id = DB[:masterfile_variants].where(masterfile_table: table_name.to_s, variant_code: variant_code).get(:masterfile_id)
      return nil if id.nil?

      get_id(table_name, args.merge(id: id))
    end

    def find_external_masterfile_mapping(id)
      hash = find_hash(:external_masterfile_mappings, id)
      return nil if hash.nil?

      mapping = lookup_mf_mapping(hash[:masterfile_table])
      hash[:mapping] = mapping[:mapping]
      hash[:masterfile_column] = mapping[:column_name]
      hash[:masterfile_code] = get(hash[:masterfile_table].to_sym, hash[:masterfile_id], hash[:masterfile_column].to_sym)

      ExternalMasterfileMapping.new(hash)
    end

    def for_select_external_mf_mapping
      array = []
      AppConst::EXTERNAL_MF_MAPPING_RULES.each do |mapping, hash|
        array << [mapping.to_s.gsub('_', ' '), hash[:table_name]]
      end
      array
    end

    def lookup_mf_mapping(table_name)
      return {} if table_name.to_s.nil_or_empty?

      mapping = AppConst::EXTERNAL_MF_MAPPING_RULES.select { |_, hash| hash.key(table_name.to_s) }
      return {} if mapping.values.empty?

      { mapping: mapping.keys.first.to_s.gsub('_', ' '),
        table_name: table_name,
        column_name: mapping.values.first[:column_name] }
    end

    def get_transformation(external_system, masterfile_table, masterfile_id)
      DB[:external_masterfile_mappings]
        .where(external_system: external_system,
               masterfile_table: masterfile_table.to_s,
               masterfile_id: masterfile_id)
        .get(:external_code)
    end

    def get_transformation_or_value(external_system, masterfile_table, masterfile_id, column)
      transformation = get_transformation(external_system, masterfile_table, masterfile_id)
      return transformation if transformation

      column ||= lookup_mf_mapping(masterfile_table)[:column_name]
      get(masterfile_table.to_sym, masterfile_id, column.to_sym)
    end
  end
end
