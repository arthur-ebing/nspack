# frozen_string_literal: true

module ProductionApp
  module ProductionRunFactory
    def create_production_run(opts = {}) # rubocop:disable Metrics/AbcSize
      farm_id = create_farm
      puc_id = create_puc
      ph_resource_id = create_plant_resource
      line_resource_id = create_plant_resource
      season_id = create_season
      orchard_id = create_orchard
      cultivar_group_id = create_cultivar_group
      cultivar_id = create_cultivar
      product_setup_template_id = create_product_setup_template

      default = {
        farm_id: farm_id,
        puc_id: puc_id,
        packhouse_resource_id: ph_resource_id,
        production_line_id: line_resource_id,
        season_id: season_id,
        orchard_id: orchard_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_id: cultivar_id,
        product_setup_template_id: product_setup_template_id,
        cloned_from_run_id: opts[:cloned_run_id],
        active_run_stage: Faker::Lorem.unique.word,
        started_at: '2010-01-01 12:00',
        closed_at: '2010-01-01 12:00',
        re_executed_at: '2010-01-01 12:00',
        completed_at: '2010-01-01 12:00',
        allow_cultivar_mixing: false,
        allow_orchard_mixing: false,
        reconfiguring: false,
        closed: false,
        setup_complete: false,
        completed: false,
        running: false,
        tipping: false,
        labeling: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        allow_cultivar_group_mixing: false
      }
      DB[:production_runs].insert(default.merge(opts))
    end

    def create_production_region(opts = {})
      default = {
        production_region_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:production_regions].insert(default.merge(opts))
    end

    def create_product_resource_allocation(opts = {})
      production_run_id = create_production_run
      product_setup_id = create_product_setup
      label_template_id = create_label_template
      packing_method_id = create_packing_method
      plant_resource_id = create_plant_resource
      target_customer_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_TARGET_CUSTOMER)

      default = {
        production_run_id: production_run_id,
        plant_resource_id: plant_resource_id,
        product_setup_id: product_setup_id,
        label_template_id: label_template_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        packing_method_id: packing_method_id,
        target_customer_party_role_id: target_customer_party_role_id
      }
      DB[:product_resource_allocations].insert(default.merge(opts))
    end
  end
end
