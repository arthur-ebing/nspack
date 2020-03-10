# frozen_string_literal: true

module MesscadaApp
  class MesscadaRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    crud_calls_for :carton_labels, name: :carton_label, wrapper: CartonLabel
    crud_calls_for :cartons, name: :carton, wrapper: Carton
    crud_calls_for :pallets, name: :pallet, wrapper: Pallet
    crud_calls_for :pallet_sequences, name: :pallet_sequence, wrapper: PalletSequence

    def find_stock_item(stock_item_id, stock_type)
      return find_pallet(stock_item_id) if stock_type == AppConst::PALLET_STOCK_TYPE

      DB[:rmt_bins].where(id: stock_item_id).first
    end

    def update_stock_item(stock_item_id, upd, stock_type)
      return update_pallet(stock_item_id, upd) if stock_type == AppConst::PALLET_STOCK_TYPE

      DB[:rmt_bins].where(id: stock_item_id).update(upd)
    end

    def where_pallets(args) # rubocop:disable Metrics/AbcSize
      has_nett_weight = args.delete(:has_nett_weight)
      has_gross_weight = args.delete(:has_gross_weight)
      on_load = args.delete(:on_load)

      ds = DB[:pallets].where(args)
      ds = ds.exclude { nett_weight.> 0 } if has_nett_weight # rubocop:disable Style/NumericPredicate
      ds = ds.exclude { gross_weight.> 0 } if has_gross_weight # rubocop:disable Style/NumericPredicate
      unless on_load.nil?
        ds = ds.exclude(load_id: on_load)
        ds = ds.exclude(load_id: nil)
      end
      ds.select_map(:pallet_number)
    end

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

    def carton_label_id_for_pallet_no(pallet_no)
      DB[:carton_labels].where(pallet_number: pallet_no.to_s).get(:id)
    end

    def pallet_exists?(pallet_number)
      exists?(:pallets, pallet_number: pallet_number)
    end

    def resource_code_exists?(resource_code)
      exists?(:system_resources, system_resource_code: resource_code)
    end

    def identifier_exists?(identifier)
      exists?(:personnel_identifiers, identifier: identifier)
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
      DB[:carton_labels].multi_insert(no_of_prints.to_i.times.map { attrs.merge(carton_equals_pallet: AppConst::CARTON_EQUALS_PALLET) }, return: :primary_key)
    end

    def carton_label_pallet_number(carton_label_id)
      return nil unless AppConst::CARTON_EQUALS_PALLET

      DB[:carton_labels].where(id: carton_label_id).get(:pallet_number)
    end

    def create_pallet(user_name, pallet)
      id = DB[:pallets].insert(pallet)
      log_status('pallets', id, AppConst::PALLETIZED_NEW_PALLET, user_name: user_name)

      id
    end

    def create_serialized_stock_movement_log(serialized_stock_movement_log)
      DB[:serialized_stock_movement_logs].insert(serialized_stock_movement_log)
    end

    def find_business_process(process)
      DB[:business_processes].where(process: process).first
    end

    def find_stock_type(stock_type_code)
      DB[:stock_types].where(stock_type_code: stock_type_code).first
    end

    def create_sequences(pallet_sequence, pallet_id)
      pallet_sequence = pallet_sequence.merge(pallet_params(pallet_id))
      DB[:pallet_sequences].insert(pallet_sequence)
    end

    # def create_pallet_and_sequences(pallet, pallet_sequence)
    #   id = DB[:pallets].insert(pallet)
    #
    #   pallet_sequence = pallet_sequence.merge(pallet_params(id))
    #   DB[:pallet_sequences].insert(pallet_sequence)
    #
    #   log_status('pallets', id, AppConst::PALLETIZED_NEW_PALLET)
    #   # ProductionApp::RunStatsUpdateJob.enqueue(production_run_id, 'PALLET_CREATED')
    #
    #   { success: true }
    # end

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
      DB[<<~SQL, bin_id].first
        SELECT b.id, b.farm_id, b.orchard_id, b.cultivar_id
        ,c.cultivar_name, c.cultivar_group_id, cg.cultivar_group_code,f.farm_code, o.orchard_code
        FROM rmt_bins b
        JOIN cultivars c ON c.id=b.cultivar_id
        JOIN cultivar_groups cg ON cg.id=c.cultivar_group_id
        JOIN farms f ON f.id=b.farm_id
        JOIN orchards o ON o.id=b.orchard_id
        WHERE b.id = ?
      SQL
    end

    def get_run_setup_reqs(run_id)
      ProductionApp::ProductionRunRepo.new.find_production_run_flat(run_id).to_h
      # DB["select r.id, r.farm_id, r.orchard_id, r.cultivar_group_id, r.cultivar_id, r.allow_cultivar_mixing, r.allow_orchard_mixing
      #   ,c.cultivar_name, cg.cultivar_group_code,f.farm_code, o.orchard_code, p.puc_code
      #   from production_runs r
      #   left join cultivars c on c.id=r.cultivar_id
      #   join cultivar_groups cg on cg.id=r.cultivar_group_id
      #   join farms f on f.id=r.farm_id
      #   join orchards o on o.id=r.orchard_id
      #   join pucs p on p.id=r.puc_id
      #   WHERE r.id = ?", run_id].first
    end

    def get_pallet_by_carton_label_id(carton_label_id)
      pallet = DB["select p.pallet_number
          from pallets p
          join pallet_sequences ps on p.id = ps.pallet_id
          join cartons c on c.id = ps.scanned_from_carton_id
          join carton_labels cl on cl.id = c.carton_label_id
          where cl.id = ?", carton_label_id].first
      return pallet[:pallet_number] unless pallet.nil?
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
          order by sis.pallet_sequence_number asc"].map { |s| s[:id] }
    end

    def find_pallet_sequence_attrs(id)
      DB["SELECT *
          FROM vw_pallet_sequence_flat
          WHERE id = ?", id].first
    end

    def update_pallet_sequence_verification_result(pallet_sequence_id, params)
      nett_weight_upd = ", nett_weight=#{params[:nett_weight]} " if params[:nett_weight]
      upd = "UPDATE pallet_sequences SET verified=true,verified_at='#{Time.now}',verification_result = '#{params[:verification_result]}', verification_passed=#{params[:verification_result] != 'failed'}, pallet_verification_failure_reason_id = #{(params[:verification_result] != 'failed' ? 'Null' : "'#{params[:verification_failure_reason]}'")} #{nett_weight_upd} WHERE id = #{pallet_sequence_id};"
      DB[upd].update
    end

    def pallet_verified?(pallet_id)
      !exists?(:pallet_sequences, pallet_id: pallet_id, verified: false)
    end

    # instance of a carton label with all its relevant lookup columns
    def carton_label_printing_instance(id)
      DB[:vw_carton_label_lbl].where(carton_label_id: id).first
    end

    # instance of an allocated product setup with all its relevant lookup columns
    def allocated_product_setup_label_printing_instance(id)
      DB[:vw_carton_label_pset].where(product_resource_allocation_id: id).first
    end

    def get_run_bins_tipped(run_id)
      query = <<~SQL
        SELECT COALESCE(SUM(COALESCE(qty_bins, 0)), 0) as bins_tipped
        FROM rmt_bins
        WHERE rmt_bins.production_run_tipped_id = ?
        AND NOT scrapped
      SQL
      DB[query, run_id].first[:bins_tipped]
    end

    def display_lines_for(device)
      server_ip = URI.parse(AppConst::LABEL_SERVER_URI).host
      mtype = DB[:mes_modules]
              .where(module_code: device, server_ip: server_ip)
              .get(:module_type)
      mtype == 'robot-T200' ? 4 : 6
    end
  end
end
