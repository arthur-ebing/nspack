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

    # @param table_name [Symbol, String] the db table name.
    # @return [hash] the variant, table_name and column_name or empty hash.
    def lookup_mf_variant(table_name)
      # FIXME: temporary reversion pre code review
      return {} if table_name.nil_or_empty?

      # return {} if table_name.to_s.nil_or_empty?
      #
      # variant = AppConst::MF_VARIANT_RULES.select { |_, hash| hash.key(table_name.to_s) }
      # return {} if variant.values.empty?
      variant = AppConst::MF_VARIANT_RULES.select { |_, hash| hash.key(table_name) }

      { variant: variant.keys.first.to_s.gsub('_', ' '),
        table_name: table_name,
        column_name: variant.values.first[:column_name] }
    end
  end
end
