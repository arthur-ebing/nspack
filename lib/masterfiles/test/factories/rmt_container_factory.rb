# frozen_string_literal: true

module MasterfilesApp
  module RmtContainerFactory # rubocop:disable Metrics/ModuleLength
    def create_rmt_container_material_owner(opts = {})
      id = get_available_factory_record(:rmt_container_material_owners, opts)
      return id unless id.nil?

      opts[:rmt_container_material_type_id] ||= create_rmt_container_material_type
      opts[:rmt_material_owner_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      DB[:rmt_container_material_owners].insert(opts)
    end

    def create_rmt_code(opts = {})
      id = get_available_factory_record(:rmt_codes, opts)
      return id unless id.nil?

      opts[:rmt_variant_id] ||= create_rmt_variant
      opts[:rmt_handling_regime_id] ||= create_rmt_handling_regime

      default = {
        rmt_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:rmt_codes].insert(default.merge(opts))
    end

    def create_rmt_variant(opts = {})
      id = get_available_factory_record(:rmt_variants, opts)
      return id unless id.nil?

      opts[:cultivar_id] ||= create_cultivar

      default = {
        rmt_variant_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:rmt_variants].insert(default.merge(opts))
    end

    def create_cultivar(opts = {})
      id = get_available_factory_record(:cultivars, opts)
      return id unless id.nil?

      opts[:cultivar_group_id] ||= create_cultivar_group

      default = {
        cultivar_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        active: true,
        cultivar_code: Faker::Lorem.word
      }
      DB[:cultivars].insert(default.merge(opts))
    end

    def create_cultivar_group(opts = {})
      id = get_available_factory_record(:cultivar_groups, opts)
      return id unless id.nil?

      opts[:commodity_id] ||= create_commodity

      default = {
        cultivar_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        active: true
      }
      DB[:cultivar_groups].insert(default.merge(opts))
    end

    def create_commodity(opts = {})
      id = get_available_factory_record(:commodities, opts)
      return id unless id.nil?

      opts[:commodity_group_id] ||= create_commodity_group

      default = {
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        hs_code: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        requires_standard_counts: false,
        use_size_ref_for_edi: false,
        colour_applies: false
      }
      DB[:commodities].insert(default.merge(opts))
    end

    def create_commodity_group(opts = {})
      id = get_available_factory_record(:commodity_groups, opts)
      return id unless id.nil?

      default = {
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:commodity_groups].insert(default.merge(opts))
    end

    def create_rmt_handling_regime(opts = {})
      id = get_available_factory_record(:rmt_handling_regimes, opts)
      return id unless id.nil?

      default = {
        regime_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        for_packing: false,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:rmt_handling_regimes].insert(default.merge(opts))
    end

    def create_rmt_container_material_type(opts = {})
      id = get_available_factory_record(:rmt_container_material_types, opts)
      return id unless id.nil?

      opts[:rmt_container_type_id] ||= create_rmt_container_type
      default = {
        container_material_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        tare_weight: Faker::Number.decimal
      }
      DB[:rmt_container_material_types].insert(default.merge(opts))
    end

    def create_rmt_container_type(opts = {})
      id = get_available_factory_record(:rmt_container_types, opts)
      return id unless id.nil?

      default = {
        container_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        rmt_inner_container_type_id: nil,
        tare_weight: Faker::Number.decimal
      }
      DB[:rmt_container_types].insert(default.merge(opts))
    end
  end
end
