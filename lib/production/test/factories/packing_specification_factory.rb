# frozen_string_literal: true

module ProductionApp
  module PackingSpecificationFactory
    def create_packing_specification_item(opts = {}) # rubocop:disable Metrics/AbcSize
      pm_bom_id = create_pm_bom
      pm_mark_id = create_pm_mark
      product_setup_id = create_product_setup
      pm_product_id = create_pm_product

      default = {
        description: Faker::Lorem.unique.word,
        pm_bom_id: pm_bom_id,
        pm_mark_id: pm_mark_id,
        product_setup_id: product_setup_id,
        tu_labour_product_id: pm_product_id,
        ru_labour_product_id: pm_product_id,
        ri_labour_product_id: pm_product_id,
        fruit_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        tu_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        ru_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:packing_specification_items].insert(default.merge(opts))
    end

    # def create_product_setup_template(opts = {})
    #   cultivar_group_id = create_cultivar_group
    #   cultivar_id = create_cultivar
    #   plant_resource_id = create_plant_resource
    #   season_group_id = create_season_group
    #   season_id = create_season
    #
    #   default = {
    #     template_name: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     cultivar_group_id: cultivar_group_id,
    #     cultivar_id: cultivar_id,
    #     packhouse_resource_id: plant_resource_id,
    #     production_line_id: plant_resource_id,
    #     season_group_id: season_group_id,
    #     season_id: season_id,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00'
    #   }
    #   DB[:product_setup_templates].insert(default.merge(opts))
    # end
    #
    # def create_cultivar_group(opts = {})
    #   commodity_id = create_commodity
    #
    #   default = {
    #     cultivar_group_code: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     active: true,
    #     commodity_id: commodity_id
    #   }
    #   DB[:cultivar_groups].insert(default.merge(opts))
    # end
    #
    # def create_commodity(opts = {})
    #   commodity_group_id = create_commodity_group
    #
    #   default = {
    #     commodity_group_id: commodity_group_id,
    #     code: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     hs_code: Faker::Lorem.word,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     requires_standard_counts: false,
    #     use_size_ref_for_edi: false
    #   }
    #   DB[:commodities].insert(default.merge(opts))
    # end
    #
    # def create_commodity_group(opts = {})
    #   default = {
    #     code: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00'
    #   }
    #   DB[:commodity_groups].insert(default.merge(opts))
    # end
    #
    # def create_cultivar(opts = {})
    #   default = {
    #     commodity_id: commodity_id,
    #     cultivar_group_id: cultivar_group_id,
    #     cultivar_name: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     active: true,
    #     cultivar_code: Faker::Lorem.word
    #   }
    #   DB[:cultivars].insert(default.merge(opts))
    # end
    #
    # def create_plant_resource(opts = {})
    #   plant_resource_type_id = create_plant_resource_type
    #   system_resource_id = create_system_resource
    #   location_id = create_location
    #
    #   default = {
    #     plant_resource_type_id: plant_resource_type_id,
    #     system_resource_id: system_resource_id,
    #     plant_resource_code: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     location_id: location_id,
    #     resource_properties: {}
    #   }
    #   DB[:plant_resources].insert(default.merge(opts))
    # end
    #
    # def create_plant_resource_type(opts = {})
    #   default = {
    #     plant_resource_type_code: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     icon: Faker::Lorem.word,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     packpoint: false
    #   }
    #   DB[:plant_resource_types].insert(default.merge(opts))
    # end
    #
    # def create_system_resource(opts = {})
    #   system_resource_type_id = create_system_resource_type
    #
    #   default = {
    #     plant_resource_type_id: plant_resource_type_id,
    #     system_resource_type_id: system_resource_type_id,
    #     system_resource_code: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     equipment_type: Faker::Lorem.word,
    #     module_function: Faker::Lorem.word,
    #     mac_address: Faker::Lorem.word,
    #     ip_address: Faker::Lorem.word,
    #     port: Faker::Number.number(digits: 4),
    #     ttl: Faker::Number.number(digits: 4),
    #     cycle_time: Faker::Number.number(digits: 4),
    #     publishing: false,
    #     login: false,
    #     logoff: false,
    #     module_action: Faker::Lorem.word,
    #     peripheral_model: Faker::Lorem.word,
    #     connection_type: Faker::Lorem.word,
    #     printer_language: Faker::Lorem.word,
    #     print_username: Faker::Lorem.word,
    #     print_password: Faker::Lorem.word,
    #     pixels_mm: Faker::Number.number(digits: 4),
    #     robot_function: Faker::Lorem.word,
    #     group_incentive: false
    #   }
    #   DB[:system_resources].insert(default.merge(opts))
    # end
    #
    # def create_system_resource_type(opts = {})
    #   default = {
    #     system_resource_type_code: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     computing_device: false,
    #     peripheral: false,
    #     icon: Faker::Lorem.word,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00'
    #   }
    #   DB[:system_resource_types].insert(default.merge(opts))
    # end
    #
    # def create_location(opts = {})
    #   location_storage_type_id = create_location_storage_type
    #   location_type_id = create_location_type
    #   location_assignment_id = create_location_assignment
    #   location_storage_definition_id = create_location_storage_definition
    #
    #   default = {
    #     primary_storage_type_id: location_storage_type_id,
    #     location_type_id: location_type_id,
    #     primary_assignment_id: location_assignment_id,
    #     location_long_code: Faker::Lorem.unique.word,
    #     location_description: Faker::Lorem.word,
    #     active: true,
    #     has_single_container: false,
    #     virtual_location: false,
    #     consumption_area: false,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     location_short_code: Faker::Lorem.unique.word,
    #     can_be_moved: false,
    #     print_code: Faker::Lorem.word,
    #     location_storage_definition_id: location_storage_definition_id,
    #     can_store_stock: false,
    #     units_in_location: Faker::Number.number(digits: 4)
    #   }
    #   DB[:locations].insert(default.merge(opts))
    # end
    #
    # def create_location_storage_type(opts = {})
    #   default = {
    #     storage_type_code: Faker::Lorem.unique.word,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     location_short_code_prefix: Faker::Lorem.word
    #   }
    #   DB[:location_storage_types].insert(default.merge(opts))
    # end
    #
    # def create_location_type(opts = {})
    #   default = {
    #     location_type_code: Faker::Lorem.unique.word,
    #     short_code: Faker::Lorem.word,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     can_be_moved: false,
    #     hierarchical: false
    #   }
    #   DB[:location_types].insert(default.merge(opts))
    # end
    #
    # def create_location_assignment(opts = {})
    #   default = {
    #     assignment_code: Faker::Lorem.unique.word,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00'
    #   }
    #   DB[:location_assignments].insert(default.merge(opts))
    # end
    #
    # def create_location_storage_definition(opts = {})
    #   default = {
    #     storage_definition_code: Faker::Lorem.unique.word,
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00',
    #     storage_definition_format: Faker::Lorem.word,
    #     storage_definition_description: Faker::Lorem.word
    #   }
    #   DB[:location_storage_definitions].insert(default.merge(opts))
    # end
    #
    # def create_season_group(opts = {})
    #   default = {
    #     season_group_code: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     season_group_year: Faker::Number.number(digits: 4),
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00'
    #   }
    #   DB[:season_groups].insert(default.merge(opts))
    # end
    #
    # def create_season(opts = {})
    #   default = {
    #     season_group_id: season_group_id,
    #     commodity_id: commodity_id,
    #     season_code: Faker::Lorem.unique.word,
    #     description: Faker::Lorem.word,
    #     season_year: Faker::Number.number(digits: 4),
    #     start_date: '2010-01-01',
    #     end_date: '2010-01-01',
    #     active: true,
    #     created_at: '2010-01-01 12:00',
    #     updated_at: '2010-01-01 12:00'
    #   }
    #   DB[:seasons].insert(default.merge(opts))
    # end
  end
end
