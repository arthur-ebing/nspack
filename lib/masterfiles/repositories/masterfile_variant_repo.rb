# frozen_string_literal: true

module MasterfilesApp
  class MasterfileVariantRepo < BaseRepo
    build_for_select :masterfile_variants,
                     label: :masterfile_table,
                     value: :id,
                     no_active_check: true,
                     order_by: :masterfile_table

    crud_calls_for :masterfile_variants, name: :masterfile_variant, wrapper: MasterfileVariant

    def lookup_mf_code(id)
      query = <<~SQL
        SELECT
          CASE masterfile_table
           WHEN 'marks' THEN
             (SELECT mark_code FROM marks WHERE id = masterfile_id)
           WHEN 'grades' THEN
             (SELECT grade_code FROM grades WHERE id = masterfile_id)
           WHEN 'pucs' THEN
             (SELECT puc_code FROM pucs WHERE id = masterfile_id)
           WHEN 'inventory_codes' THEN
             (SELECT inventory_code FROM inventory_codes WHERE id = masterfile_id)
           WHEN 'standard_pack_codes' THEN
             (SELECT standard_pack_code FROM standard_pack_codes WHERE id = masterfile_id)
           WHEN 'marketing_varieties' THEN
             (SELECT marketing_variety_code FROM marketing_varieties WHERE id = masterfile_id)
           WHEN 'fruit_size_references' THEN
             (SELECT size_reference FROM fruit_size_references WHERE id = masterfile_id)
           WHEN 'packed_tm_group' THEN
             (SELECT target_market_group_name FROM target_market_groups WHERE id = masterfile_id)
            ELSE
             NULL
           END AS masterfile_value
        FROM masterfile_variants
        WHERE id = ?
      SQL
      DB[query, id].get(:masterfile_value)
    end

    def selected_masterfile(table_name, id)
      DB[:vw_masterfiles_for_variants].where(masterfile_table: table_name, id: id).select(:id, :lookup_code).first
    end
  end
end
