# frozen_string_literal: true

module MesscadaApp
  class MesscadaRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    crud_calls_for :carton_labels, name: :carton_label, wrapper: CartonLabel
    crud_calls_for :cartons, name: :carton, wrapper: Carton
    crud_calls_for :pallets, name: :pallet, wrapper: Pallet
    crud_calls_for :pallet_sequences, name: :pallet_sequence, wrapper: PalletSequence

    def carton_label_exists?(carton_label_id)
      exists?(:carton_labels, id: carton_label_id)
    end

    def carton_label_carton_exists?(carton_label_id)
      exists?(:cartons, carton_label_id: carton_label_id)
    end

    def carton_exists?(carton_id)
      exists?(:cartons, id: carton_id)
    end

    def carton_label_carton_id(carton_label_id)
      DB[:cartons].where(carton_label_id: carton_label_id).get(:id)
    end

    def resource_code_exists?(resource_code)
      exists?(:system_resources, system_resource_code: resource_code)
    end

    def production_run_exists?(production_run_id)
      exists?(:production_runs, id: production_run_id)
    end

    def standard_pack_code_exists?(plant_resource_button_indicator)
      exists?(:standard_pack_codes, plant_resource_button_indicator: plant_resource_button_indicator)
    end

    def one_standard_pack_code?(plant_resource_button_indicator)
      DB[:standard_pack_codes].where(plant_resource_button_indicator: plant_resource_button_indicator).count == 1
    end

    def find_standard_pack_code(plant_resource_button_indicator)
      DB[:standard_pack_codes].where(plant_resource_button_indicator: plant_resource_button_indicator).get(:id)
    end

    def find_standard_pack_code_material_mass(id)
      DB[:standard_pack_codes].where(id: id).get(:material_mass)
    end

    def find_pallet_from_carton(carton_id)
      DB[:pallet_sequences].where(scanned_from_carton_id: carton_id).get(:pallet_id)
    end

    def find_resource_location_id(id)
      DB[:plant_resources].where(id: id).get(:location_id)
    end

    def find_resource_phc(id)
      # DB[:plant_resources].where(id: id).select(:id, Sequel.lit("resource_properties ->> 'phc'").as(:phc)).first[:phc].to_s
      DB[:plant_resources].where(id: id).get(Sequel.lit("resource_properties ->> 'phc'"))
    end

    def find_resource_packhouse_no(id)
      # DB[:plant_resources].where(id: id).select(:id, Sequel.lit("resource_properties ->> 'packhouse_no'").as(:packhouse_no)).first[:packhouse_no].to_s
      DB[:plant_resources].where(id: id).get(Sequel.lit("resource_properties ->> 'packhouse_no'"))
    end

    def find_cartons_per_pallet(id)
      DB[:cartons_per_pallet].where(id: id).get(:cartons_per_pallet)
    end

    # Create several carton_labels records returning an array of the newly-created ids
    def create_carton_labels(no_of_prints, attrs)
      DB[:carton_labels].multi_insert(no_of_prints.times.map { attrs }, return: :primary_key)
    end

    def create_pallet_and_sequences(pallet, pallet_sequence)
      id = DB[:pallets].insert(pallet)

      pallet_sequence = pallet_sequence.merge(pallet_params(id))
      DB[:pallet_sequences].insert(pallet_sequence)

      log_status('pallets', id, AppConst::PALLETIZED_NEW_PALLET)
      # ProductionApp::RunStatsUpdateJob.enqueue(production_run_id, 'PALLET_CREATED')

      { success: true }
    end

    def pallet_params(pallet_id)
      {
        pallet_id: pallet_id,
        pallet_number: find_pallet_number(pallet_id)
      }
    end

    def find_pallet_number(id)
      DB[:pallets].where(id: id).get(:pallet_number)
    end

    # def find_rmt_container_type_tare_weight(rmt_container_type_id)
    #   DB[:rmt_container_types].where(id: rmt_container_type_id).map { |o| o[:tare_weight] }.first
    # end
    #
    def get_rmt_bin_setup_reqs(bin_id)
      DB["select b.id, b.farm_id, b.orchard_id, b.cultivar_id
        ,c.cultivar_name, c.cultivar_group_id, cg.cultivar_group_code,f.farm_code, o.orchard_code
        from rmt_bins b
        join cultivars c on c.id=b.cultivar_id
        join cultivar_groups cg on cg.id=c.cultivar_group_id
        join farms f on f.id=b.farm_id
        join orchards o on o.id=b.orchard_id
        WHERE b.id = ?", bin_id].first
    end

    def get_run_setup_reqs(run_id)
      DB["select r.id, r.farm_id, r.orchard_id, r.cultivar_group_id, r.cultivar_id, r.allow_cultivar_mixing, r.allow_orchard_mixing
        ,c.cultivar_name, cg.cultivar_group_code,f.farm_code, o.orchard_code, p.puc_code
        from production_runs r
        join cultivars c on c.id=r.cultivar_id
        join cultivar_groups cg on cg.id=r.cultivar_group_id
        join farms f on f.id=r.farm_id
        join orchards o on o.id=r.orchard_id
        join pucs p on p.id=r.puc_id
        WHERE r.id = ?", run_id].first
    end

    def production_run_stats(run_id)
      DB[:production_run_stats].where(production_run_id: run_id).map { |p| p[:bins_tipped] }.first
    end

    def find_pallet_sequences_by_pallet_number(pallet_number)
      # DB[:vw_pallet_sequence_flat].where(pallet_number: pallet_number)
      DB["SELECT *
          FROM vw_pallet_sequence_flat
          WHERE pallet_number = '#{pallet_number}'
          order by pallet_sequence_number asc"]
    end

    def find_pallet_sequences_from_same_pallet(id)
      DB["select sis.id
          from pallet_sequences s
          join pallet_sequences sis on sis.pallet_id=s.pallet_id
          where s.id = #{id}
          order by s.pallet_sequence_number asc"].map { |s| s[:id] }
    end

    def find_pallet_sequence_attrs(id)
      DB["SELECT *
          FROM vw_pallet_sequence_flat
          WHERE id = ?", id].first
    end
  end
end
