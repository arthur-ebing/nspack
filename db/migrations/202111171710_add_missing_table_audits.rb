Sequel.migration do
  up do
    run <<~SQL
      SELECT audit.audit_table('basic_pack_codes', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('commodities', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('commodity_groups', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('contract_workers', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('cultivar_groups', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('cultivars', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('destination_cities', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('destination_countries', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('destination_regions', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('farm_puc_orgs', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('farm_sections', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('farms_pucs', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('fruit_actual_counts_for_packs', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('fruit_size_references', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('govt_inspection_pallets', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('govt_inspection_sheets', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('inner_pm_marks', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('inspectors', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('marketing_orders', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('marketing_varieties', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('marketing_varieties_for_cultivars', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('multi_labels', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('organizations', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('pallet_mix_rules', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('parties', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('party_roles', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('people', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('rmt_container_material_owners', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('rmt_sizes', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('standard_pack_codes', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('standard_product_weights', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('std_fruit_size_counts', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('target_market_groups', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('target_markets', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('user_email_groups_users', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('vehicle_job_units', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('vehicle_jobs', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('wage_levels', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('work_order_items', true, true, '{updated_at}'::text[]);
      SELECT audit.audit_table('work_orders', true, true, '{updated_at}'::text[]);
    SQL
  end

  down do
    drop_trigger(:basic_pack_codes, :audit_trigger_row)
    drop_trigger(:basic_pack_codes, :audit_trigger_stm)
    drop_trigger(:commodities, :audit_trigger_row)
    drop_trigger(:commodities, :audit_trigger_stm)
    drop_trigger(:commodity_groups, :audit_trigger_row)
    drop_trigger(:commodity_groups, :audit_trigger_stm)
    drop_trigger(:contract_workers, :audit_trigger_row)
    drop_trigger(:contract_workers, :audit_trigger_stm)
    drop_trigger(:cultivar_groups, :audit_trigger_row)
    drop_trigger(:cultivar_groups, :audit_trigger_stm)
    drop_trigger(:cultivars, :audit_trigger_row)
    drop_trigger(:cultivars, :audit_trigger_stm)
    drop_trigger(:destination_cities, :audit_trigger_row)
    drop_trigger(:destination_cities, :audit_trigger_stm)
    drop_trigger(:destination_countries, :audit_trigger_row)
    drop_trigger(:destination_countries, :audit_trigger_stm)
    drop_trigger(:destination_regions, :audit_trigger_row)
    drop_trigger(:destination_regions, :audit_trigger_stm)
    drop_trigger(:farm_puc_orgs, :audit_trigger_row)
    drop_trigger(:farm_puc_orgs, :audit_trigger_stm)
    drop_trigger(:farm_sections, :audit_trigger_row)
    drop_trigger(:farm_sections, :audit_trigger_stm)
    drop_trigger(:farms_pucs, :audit_trigger_row)
    drop_trigger(:farms_pucs, :audit_trigger_stm)
    drop_trigger(:fruit_actual_counts_for_packs, :audit_trigger_row)
    drop_trigger(:fruit_actual_counts_for_packs, :audit_trigger_stm)
    drop_trigger(:fruit_size_references, :audit_trigger_row)
    drop_trigger(:fruit_size_references, :audit_trigger_stm)
    drop_trigger(:govt_inspection_pallets, :audit_trigger_row)
    drop_trigger(:govt_inspection_pallets, :audit_trigger_stm)
    drop_trigger(:govt_inspection_sheets, :audit_trigger_row)
    drop_trigger(:govt_inspection_sheets, :audit_trigger_stm)
    drop_trigger(:inner_pm_marks, :audit_trigger_row)
    drop_trigger(:inner_pm_marks, :audit_trigger_stm)
    drop_trigger(:inspectors, :audit_trigger_row)
    drop_trigger(:inspectors, :audit_trigger_stm)
    drop_trigger(:marketing_orders, :audit_trigger_row)
    drop_trigger(:marketing_orders, :audit_trigger_stm)
    drop_trigger(:marketing_varieties, :audit_trigger_row)
    drop_trigger(:marketing_varieties, :audit_trigger_stm)
    drop_trigger(:marketing_varieties_for_cultivars, :audit_trigger_row)
    drop_trigger(:marketing_varieties_for_cultivars, :audit_trigger_stm)
    drop_trigger(:multi_labels, :audit_trigger_row)
    drop_trigger(:multi_labels, :audit_trigger_stm)
    drop_trigger(:organizations, :audit_trigger_row)
    drop_trigger(:organizations, :audit_trigger_stm)
    drop_trigger(:pallet_mix_rules, :audit_trigger_row)
    drop_trigger(:pallet_mix_rules, :audit_trigger_stm)
    drop_trigger(:parties, :audit_trigger_row)
    drop_trigger(:parties, :audit_trigger_stm)
    drop_trigger(:party_roles, :audit_trigger_row)
    drop_trigger(:party_roles, :audit_trigger_stm)
    drop_trigger(:people, :audit_trigger_row)
    drop_trigger(:people, :audit_trigger_stm)
    drop_trigger(:rmt_container_material_owners, :audit_trigger_row)
    drop_trigger(:rmt_container_material_owners, :audit_trigger_stm)
    drop_trigger(:rmt_sizes, :audit_trigger_row)
    drop_trigger(:rmt_sizes, :audit_trigger_stm)
    drop_trigger(:standard_pack_codes, :audit_trigger_row)
    drop_trigger(:standard_pack_codes, :audit_trigger_stm)
    drop_trigger(:standard_product_weights, :audit_trigger_row)
    drop_trigger(:standard_product_weights, :audit_trigger_stm)
    drop_trigger(:std_fruit_size_counts, :audit_trigger_row)
    drop_trigger(:std_fruit_size_counts, :audit_trigger_stm)
    drop_trigger(:target_market_groups, :audit_trigger_row)
    drop_trigger(:target_market_groups, :audit_trigger_stm)
    drop_trigger(:target_markets, :audit_trigger_row)
    drop_trigger(:target_markets, :audit_trigger_stm)
    drop_trigger(:user_email_groups_users, :audit_trigger_row)
    drop_trigger(:user_email_groups_users, :audit_trigger_stm)
    drop_trigger(:vehicle_job_units, :audit_trigger_row)
    drop_trigger(:vehicle_job_units, :audit_trigger_stm)
    drop_trigger(:vehicle_jobs, :audit_trigger_row)
    drop_trigger(:vehicle_jobs, :audit_trigger_stm)
    drop_trigger(:wage_levels, :audit_trigger_row)
    drop_trigger(:wage_levels, :audit_trigger_stm)
    drop_trigger(:work_order_items, :audit_trigger_row)
    drop_trigger(:work_order_items, :audit_trigger_stm)
    drop_trigger(:work_orders, :audit_trigger_row)
    drop_trigger(:work_orders, :audit_trigger_stm)
  end
end
