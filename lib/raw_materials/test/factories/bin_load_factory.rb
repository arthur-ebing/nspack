# frozen_string_literal: true

module RawMaterialsApp
  module BinLoadFactory
    def create_bin_load_purpose(opts = {})
      default = {
        purpose_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:bin_load_purposes].insert(default.merge(opts))
    end

    def create_bin_load(opts = {}, add_product: true)
      qty_bins = Faker::Number.number(4)
      bin_load_purpose_id = create_bin_load_purpose
      party_role_id = create_party_role
      depot_id = create_depot

      default = {
        bin_load_purpose_id: bin_load_purpose_id,
        customer_party_role_id: party_role_id,
        transporter_party_role_id: party_role_id,
        dest_depot_id: depot_id,
        qty_bins: qty_bins,
        shipped_at: '2010-01-01 12:00',
        shipped: false,
        completed_at: '2010-01-01 12:00',
        completed: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      bin_load_id = DB[:bin_loads].insert(default.merge(opts))
      create_bin_load_product(bin_load_id: bin_load_id, qty_bins: qty_bins) if add_product
      bin_load_id
    end

    def create_bin_load_product(opts = {}) # rubocop:disable Metrics/AbcSize
      bin_load_id = opts[:bin_load_id] || create_bin_load
      cultivar_id = create_cultivar
      cultivar_group_id = create_cultivar_group
      rmt_container_material_type_id = create_rmt_container_material_type
      party_role_id = create_party_role('P', AppConst::ROLE_RMT_BIN_OWNER)
      farm_id = create_farm
      puc_id = create_puc
      orchard_id = create_orchard
      rmt_class_id = create_rmt_class

      default = {
        bin_load_id: bin_load_id,
        qty_bins: Faker::Number.number(4),
        cultivar_id: cultivar_id,
        cultivar_group_id: cultivar_group_id,
        rmt_container_material_type_id: rmt_container_material_type_id,
        rmt_material_owner_party_role_id: party_role_id,
        farm_id: farm_id,
        puc_id: puc_id,
        orchard_id: orchard_id,
        rmt_class_id: rmt_class_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:bin_load_products].insert(default.merge(opts))
    end
  end
end
