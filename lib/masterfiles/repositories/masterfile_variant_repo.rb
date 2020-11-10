# frozen_string_literal: true

module MasterfilesApp
  class MasterfileVariantRepo < BaseRepo
    crud_calls_for :masterfile_variants, name: :masterfile_variant, wrapper: MasterfileVariant

    def find_masterfile_variant_flat(id)
      hash = find_hash(:masterfile_variants, id)
      return nil if hash.nil?

      variant = lookup_mf_variant(hash[:masterfile_table])
      hash[:variant] = variant[:variant]
      hash[:masterfile_column] = variant[:column_name]
      hash[:masterfile_code] = get(hash[:masterfile_table].to_sym, hash[:masterfile_id], hash[:masterfile_column].to_sym)

      MasterfileVariantFlat.new(hash)
    end

    def for_select_mf_variant
      array = []
      AppConst::MF_VARIANT_RULES.each do |variant, hash|
        array << [variant.to_s.gsub('_', ' '), hash[:table_name]]
      end
      array
    end

    def lookup_mf_variant(table_name)
      return {} if table_name.nil_or_empty?

      variant = AppConst::MF_VARIANT_RULES.select { |_, hash| hash.key(table_name) }
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
      id = DB[:masterfile_variants].where(masterfile_table: table_name, variant_code: variant_code).get(:masterfile_id)
      return nil if id.nil?

      get_id(table_name, args.merge(id: id))
    end
  end
end
