# frozen_string_literal: true

module MasterfilesApp
  class GeneralRepo < BaseRepo
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

    crud_calls_for :masterfile_transformations, name: :masterfile_transformation

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
      hash[:masterfile_code] = get(hash[:masterfile_table].to_sym, hash[:masterfile_column].to_sym, hash[:masterfile_id])

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

    def find_masterfile_transformation(id)
      hash = find_hash(:masterfile_transformations, id)
      return nil if hash.nil?

      transformation = lookup_mf_transformation(hash[:masterfile_table])
      hash[:transformation] = transformation[:transformation]
      hash[:masterfile_column] = transformation[:column_name]
      hash[:masterfile_code] = get(hash[:masterfile_table].to_sym, hash[:masterfile_column].to_sym, hash[:masterfile_id])

      MasterfileTransformation.new(hash)
    end

    def for_select_mf_transformation
      array = []
      AppConst::MF_TRANSFORMATION_RULES.each do |transformation, hash|
        array << [transformation.to_s.gsub('_', ' '), hash[:table_name]]
      end
      array
    end

    def lookup_mf_transformation(table_name)
      return {} if table_name.to_s.nil_or_empty?

      transformation = AppConst::MF_TRANSFORMATION_RULES.select { |_, hash| hash.key(table_name.to_s) }
      return {} if transformation.values.empty?

      { transformation: transformation.keys.first.to_s.gsub('_', ' '),
        table_name: table_name,
        column_name: transformation.values.first[:column_name] }
    end

    def get_transformation(external_system, masterfile_table, masterfile_id)
      DB[:masterfile_transformations]
        .where(external_system: external_system,
               masterfile_table: masterfile_table.to_s,
               masterfile_id: masterfile_id)
        .get(:external_code)
    end

    def get_transformation_or_value(external_system, table_name, id, column)
      transformation = get_transformation(external_system, table_name, id)
      return transformation if transformation

      column ||= lookup_mf_transformation(masterfile_table)[:column_name]
      get(table_name.to_sym, column.to_sym, id)
    end
  end
end
