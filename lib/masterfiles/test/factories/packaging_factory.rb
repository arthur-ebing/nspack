# frozen_string_literal: true

module MasterfilesApp
  module PackagingFactory  # rubocop:disable Metrics/ModuleLength
    def create_pallet_base(opts = {})
      default = {
        pallet_base_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        length: Faker::Number.number(4),
        width: Faker::Number.number(4),
        edi_in_pallet_base: Faker::Lorem.word,
        edi_out_pallet_base: Faker::Lorem.word,
        cartons_per_layer: Faker::Number.number(4),
        material_mass: Faker::Number.decimal,
        active: true
      }
      DB[:pallet_bases].insert(default.merge(opts))
    end

    def create_pallet_stack_type(opts = {})
      default = {
        stack_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        stack_height: Faker::Number.number(4),
        active: true
      }
      DB[:pallet_stack_types].insert(default.merge(opts))
    end

    def create_pallet_format(opts = {})
      pallet_base_id = create_pallet_base
      pallet_stack_type_id = create_pallet_stack_type

      default = {
        description: Faker::Lorem.unique.word,
        pallet_base_id: pallet_base_id,
        pallet_stack_type_id: pallet_stack_type_id,
        active: true
      }
      DB[:pallet_formats].insert(default.merge(opts))
    end

    def create_cartons_per_pallet(opts = {})
      pallet_format_id = create_pallet_format
      basic_pack_code_id = create_basic_pack_code

      default = {
        description: Faker::Lorem.unique.word,
        pallet_format_id: pallet_format_id,
        basic_pack_id: basic_pack_code_id,
        cartons_per_pallet: Faker::Number.number(4),
        layers_per_pallet: Faker::Number.number(4),
        active: true
      }
      DB[:cartons_per_pallet].insert(default.merge(opts))
    end

    def create_pm_type(opts = {})
      default = {
        pm_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:pm_types].insert(default.merge(opts))
    end

    def create_pm_subtype(opts = {})
      pm_type_id = create_pm_type

      default = {
        pm_type_id: pm_type_id,
        subtype_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:pm_subtypes].insert(default.merge(opts))
    end

    def create_pm_product(opts = {})
      pm_subtype_id = create_pm_subtype

      default = {
        pm_subtype_id: pm_subtype_id,
        erp_code: Faker::Lorem.unique.word,
        product_code: Faker::Lorem.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:pm_products].insert(default.merge(opts))
    end

    def create_pm_bom(opts = {})
      default = {
        bom_code: Faker::Lorem.unique.word,
        erp_bom_code: Faker::Lorem.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:pm_boms].insert(default.merge(opts))
    end

    def create_pm_boms_product(opts = {})
      pm_product_id = create_pm_product
      pm_bom_id = create_pm_bom
      uom_id = create_uom

      default = {
        pm_product_id: pm_product_id,
        pm_bom_id: pm_bom_id,
        uom_id: uom_id,
        quantity: Faker::Number.decimal,
        active: true
      }
      DB[:pm_boms_products].insert(default.merge(opts))
    end

    def create_packing_method(opts = {})
      default = {
        packing_method_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        actual_count_reduction_factor: Faker::Number.decimal,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:packing_methods].insert(default.merge(opts))
    end
  end
end
