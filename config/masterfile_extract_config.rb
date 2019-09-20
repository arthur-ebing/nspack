# frozen_string_literal: true

module Crossbeams
  module Config # rubocop:disable Metrics/ModuleLength
    MF_BASE_TABLES = %i[
      address_types
      basic_pack_codes
      commodity_groups
      contact_method_types
      cultivar_groups
      destination_regions
      fruit_size_references
      grades
      inventory_codes
      location_assignments
      location_storage_definitions
      location_storage_types
      location_types
      marketing_varieties
      marks
      master_lists
      pallet_bases
      pallet_stack_types
      parties
      plant_resource_types
      pm_boms
      pm_types
      production_regions
      pucs
      rmt_classes
      rmt_delivery_destinations
      roles
      season_groups
      standard_pack_codes
      system_resource_types
      target_market_group_types
      target_markets
      treatment_types
      uoms
      user_email_groups
    ].freeze

    # These are all complicated by the party model
    # MF_TABLES_IN_SEQ = %i[
    #   party_addresses
    #   party_contact_methods
    #   party_roles
    #   farm_groups
    #   farms
    #   rmt_container_material_owners
    # ].freeze

    #   rmt_container_types :: where inner NULL; where inner not null
    MF_TABLES_SELF_REF = [
      { table: :rmt_container_types, key: :rmt_inner_container_type_id }
    ].freeze

    MF_TABLES_IN_SEQ = %i[
      addresses
      commodities
      contact_methods
      cultivars
      pallet_formats
      cartons_per_pallet
      destination_countries
      destination_cities
      locations
      location_assignments_locations
      location_storage_types_locations
      tree_locations
      system_resources
      plant_resources
      plant_resources_system_resources
      tree_plant_resources
      marketing_varieties_for_cultivars
      pm_subtypes
      pm_products
      pm_boms_products
      seasons
      std_fruit_size_counts
      target_market_groups
      target_markets_for_groups
      target_markets_for_countries
      customer_varieties
      customer_variety_varieties
      organizations
      people

      farms_pucs
      rmt_container_material_types
      orchards

      fruit_actual_counts_for_packs
      treatments
    ].freeze

    # For arrays of ids
    MF_LKP_ARRAY_RULES = {
      cultivar_ids: { subquery: 'SELECT array_agg(id) FROM cultivars WHERE cultivar_name IN ?', values: 'SELECT cultivar_name FROM cultivars WHERE id IN ?' }, # && commodity? :cultivar_id
      standard_pack_code_ids: { subquery: 'SELECT array_agg(id) FROM standard_pack_codes WHERE standard_pack_code IN ?', values: 'SELECT standard_pack_code FROM standard_pack_codes WHERE id IN ?' }
    }.freeze

    # The subquery is the subquery to be injected in the INSERT statement.
    # The values gets the key value to be used in the subquery for a particular row.
    MF_LKP_RULES = {
      address_id: { subquery: 'SELECT id FROM addresss WHERE address_type_id = ? AND address_line_1 = ? AND address_line_2 = ? AND city = ?', values: 'SELECT address_type_id, address_line_1, address_line_2, city FROM addresss WHERE id = ?' },
      address_type_id: { subquery: 'SELECT id FROM address_types WHERE address_type = ?', values: 'SELECT address_type FROM address_types WHERE id = ?' },
      contact_method_type_id: { subquery: 'SELECT id FROM contact_method_types WHERE contact_method_type = ?', values: 'SELECT contact_method_type FROM contact_method_types WHERE id = ?' },
      commodity_group_id: { subquery: 'SELECT id FROM commodity_groups WHERE code = ?', values: 'SELECT code FROM commodity_groups WHERE id = ?' },
      commodity_id: { subquery: 'SELECT id FROM commodities WHERE code = ?', values: 'SELECT code FROM commodities WHERE id = ?' },
      cultivar_group_id: { subquery: 'SELECT id FROM cultivar_groups WHERE cultivar_group_code = ?', values: 'SELECT cultivar_group_code FROM cultivar_groups WHERE id = ?' },
      cultivar_id: { subquery: 'SELECT id FROM cultivars WHERE cultivar_name = ?', values: 'SELECT cultivar_name FROM cultivars WHERE id = ?' }, # && commodity?
      # party_id: { subquery: 'SELECT id FROM parties WHERE cultivar_name = ?', values: 'SELECT cultivar_name FROM cultivars WHERE id = ?' }
      pallet_base_id: { subquery: 'SELECT id FROM pallet_bases WHERE pallet_base_code = ?', values: 'SELECT pallet_base_code FROM pallet_bases WHERE id = ?' },
      pallet_stack_type_id: { subquery: 'SELECT id FROM pallet_stack_types WHERE pallet_stack_type_code = ?', values: 'SELECT pallet_stack_type_code FROM pallet_stack_types WHERE id = ?' },
      pallet_format_id: { subquery: 'SELECT id FROM pallet_formats WHERE pallet_base_id = (SELECT id FROM pallet_bases WHERE paller_base_code = ?) AND pallet_stack_type_id = (SELECT id FROM pallet_stack_types WHERE pallet_stack_type_code = ?)', values: 'SELECT b.pallet_base_code, s.pallet_stack_type_code FROM pallet_formats f JOIN pallet_bases b ON b.id = f.pallet_base_id JOIN pallet_stack_types s ON s.id = f.pallet_stack_type_id WHERE id = ?' },
      basic_pack_id: { subquery: 'SELECT id FROM basic_pack_codes WHERE basic_pack_code = ?', values: 'SELECT basic_pack_code FROM basic_pack_codes WHERE id = ?' },
      basic_pack_code_id: { subquery: 'SELECT id FROM basic_pack_codes WHERE basic_pack_code = ?', values: 'SELECT basic_pack_code FROM basic_pack_codes WHERE id = ?' },
      destination_region_id: { subquery: 'SELECT id FROM destination_regions WHERE destination_region_name = ?', values: 'SELECT destination_region_name FROM destination_regions WHERE id = ?' },
      destination_country_id: { subquery: 'SELECT id FROM destination_countries WHERE country_name = ?', values: 'SELECT country_name FROM destination_countries WHERE id = ?' },
      primary_storage_type_id: { subquery: 'SELECT id FROM location_storage_types WHERE storage_type_code = ?', values: 'SELECT storage_type_code FROM location_storage_types WHERE id = ?' },
      location_storage_type_id: { subquery: 'SELECT id FROM location_storage_types WHERE storage_type_code = ?', values: 'SELECT storage_type_code FROM location_storage_types WHERE id = ?' },
      location_type_id: { subquery: 'SELECT id FROM location_types WHERE location_type_code = ?', values: 'SELECT location_type_code FROM location_types WHERE id = ?' },
      primary_assignment_id: { subquery: 'SELECT id FROM location_assignments WHERE assignment_code = ?', values: 'SELECT assignment_code FROM location_assignments WHERE id = ?' },
      location_assignment_id: { subquery: 'SELECT id FROM location_assignments WHERE assignment_code = ?', values: 'SELECT assignment_code FROM location_assignments WHERE id = ?' },
      location_storage_definition_id: { subquery: 'SELECT id FROM location_storage_definitions WHERE storage_definition_code = ?', values: 'SELECT storage_definition_code FROM location_storage_definitions WHERE id = ?' },
      location_id: { subquery: 'SELECT id FROM locations WHERE location_short_code = ?', values: 'SELECT location_short_code FROM locations WHERE id = ?' },
      ancestor_location_id: { subquery: 'SELECT id FROM locations WHERE location_short_code = ?', values: 'SELECT location_short_code FROM locations WHERE id = ?' },
      descendant_location_id: { subquery: 'SELECT id FROM locations WHERE location_short_code = ?', values: 'SELECT location_short_code FROM locations WHERE id = ?' },
      marketing_variety_id: { subquery: 'SELECT id FROM marketing_varieties WHERE marketing_variety_code = ?', values: 'SELECT marketing_variety_code FROM marketing_varieties WHERE id = ?' },
      plant_resource_type_id: { subquery: 'SELECT id FROM plant_resource_types WHERE plant_resource_type_code = ?', values: 'SELECT plant_resource_type_code FROM plant_resource_types WHERE id = ?' },
      system_resource_type_id: { subquery: 'SELECT id FROM system_resource_types WHERE system_resource_type_code = ?', values: 'SELECT system_resource_type_code FROM system_resource_types WHERE id = ?' },
      plant_resource_id: { subquery: 'SELECT id FROM plant_resources WHERE plant_resource_code = ?', values: 'SELECT plant_resource_code FROM plant_resources WHERE id = ?' },
      ancestor_plant_resource_id: { subquery: 'SELECT id FROM plant_resources WHERE plant_resource_code = ?', values: 'SELECT plant_resource_code FROM plant_resources WHERE id = ?' },
      descendant_plant_resource_id: { subquery: 'SELECT id FROM plant_resources WHERE plant_resource_code = ?', values: 'SELECT plant_resource_code FROM plant_resources WHERE id = ?' },
      system_resource_id: { subquery: 'SELECT id FROM system_resources WHERE system_resource_code = ?', values: 'SELECT system_resource_code FROM system_resources WHERE id = ?' },
      pm_type_id: { subquery: 'SELECT id FROM pm_types WHERE pm_type_code = ?', values: 'SELECT pm_type_code FROM pm_types WHERE id = ?' },
      pm_subtype_id: { subquery: 'SELECT id FROM pm_subtypes WHERE subtype_code = ?', values: 'SELECT subtype_code FROM pm_subtypes WHERE id = ?' },
      pm_product_id: { subquery: 'SELECT id FROM pm_products WHERE product_code = ?', values: 'SELECT product_code FROM pm_products WHERE id = ?' },
      pm_bom_id: { subquery: 'SELECT id FROM pm_boms WHERE bom_code = ?', values: 'SELECT bom_code FROM pm_boms WHERE id = ?' },
      uom_id: { subquery: 'SELECT id FROM uoms WHERE uom_code = ?', values: 'SELECT uom_code FROM uoms WHERE id = ?' },
      season_group_id: { subquery: 'SELECT id FROM season_groups WHERE season_group_code = ?', values: 'SELECT season_group_code FROM season_groups WHERE id = ?' },
      target_market_group_type_id: { subquery: 'SELECT id FROM target_market_group_types WHERE target_market_group_type_code = ?', values: 'SELECT target_market_group_type_code FROM target_market_group_types WHERE id = ?' },
      target_market_id: { subquery: 'SELECT id FROM target_markets WHERE target_market_name = ?', values: 'SELECT target_market_name FROM target_markets WHERE id = ?' },
      target_market_group_id: { subquery: 'SELECT id FROM target_market_groups WHERE target_market_group_name = ? AND target_market_group_type_id = (SELECT id FROM target_market_group_types WHERE target_market_group_type_code = ?)', values: 'SELECT g.target_market_group_name, t.target_market_group_type_code FROM target_market_groups g JOIN target_market_group_types t ON t.id = g.target_market_group_type_id WHERE g.id = ?' },
      treatment_type_id: { subquery: 'SELECT id FROM treatment_types WHERE treatment_type_code = ?', values: 'SELECT treatment_type_code FROM treatment_types WHERE id = ?' },
      customer_variety_id: { subquery: 'SELECT id FROM marketing_varieties WHERE marketing_variety_code = ?', values: 'SELECT marketing_variety_code FROM marketing_varieties WHERE id = ?' },
      variety_as_customer_variety_id: { subquery: 'SELECT id FROM marketing_varieties WHERE marketing_variety_code = ?', values: 'SELECT marketing_variety_code FROM marketing_varieties WHERE id = ?' },
      packed_tm_group_id: { subquery: 'SELECT id FROM target_market_groups WHERE target_market_group_name = ? AND target_market_group_type_id = (SELECT id FROM target_market_group_types WHERE target_market_group_type_code = ?)', values: 'SELECT g.target_market_group_name, t.target_market_group_type_code FROM target_market_groups g JOIN target_market_group_types t ON t.id = g.target_market_group_type_id WHERE g.id = ?' },
      puc_id: { subquery: 'SELECT id FROM pucs WHERE puc_code = ?', values: 'SELECT puc_code FROM pucs WHERE id = ?' },
      farm_id: { subquery: 'SELECT id FROM farms WHERE farm_code = ?', values: 'SELECT farm_code FROM farms WHERE id = ?' },
      rmt_container_type_id: { subquery: 'SELECT id FROM rmt_container_types WHERE container_type_code = ?', values: 'SELECT container_type_code FROM rmt_container_types WHERE id = ?' },
      rmt_inner_container_type_id: { subquery: 'SELECT id FROM rmt_container_types WHERE container_type_code = ?', values: 'SELECT container_type_code FROM rmt_container_types WHERE id = ?' },
      std_fruit_size_count_id: { subquery: 'SELECT id FROM std_fruit_size_counts WHERE size_count_value = ? AND commodity_id = (SELECT id FROM commodities WHERE code = ?)', values: 'SELECT s.size_count_value, c.code FROM std_fruit_size_counts s JOIN commodities c ON c.id = s.commodity_id WHERE s.id = ?' },
      # standard_pack_code_ids, size_reference_ids, cultivar_ids
      zzz: {}
    }.freeze
  end
end
