# frozen_string_literal: true

module MesscadaApp
  class MesscadaRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    crud_calls_for :carton_labels, name: :carton_label, wrapper: CartonLabel
    crud_calls_for :cartons, name: :carton, wrapper: Carton
    crud_calls_for :pallets, name: :pallet, wrapper: Pallet
    crud_calls_for :pallet_sequences, name: :pallet_sequence, wrapper: PalletSequence

    def find_pallet_flat(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:pallets, id,
                                   lookup_functions: [{ function: :fn_current_status, args: ['pallets', :id],  col_name: :status },
                                                      { function: :fn_party_role_name, args: [:target_customer_party_role_id], col_name: :target_customer }])
      return nil if hash.nil?

      hash[:last_govt_inspection_sheet_id] = get(:govt_inspection_pallets, hash[:last_govt_inspection_pallet_id], :govt_inspection_sheet_id)
      hash[:oldest_pallets_sequence_id] = DB[:pallet_sequences].where(pallet_id: id).order(:created_at).select_map(:id).first
      hash[:nett_weight] = hash[:nett_weight].to_f.round(2)
      hash[:gross_weight] = hash[:gross_weight].to_f.round(2)

      PalletFlat.new(hash)
    end

    def find_pallet_sequence_flat(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:pallet_sequences, id,
                                   parent_tables: [{ parent_table: :farms, columns: %i[farm_code pdn_region_id], foreign_key: :farm_id, flatten_columns: { farm_code: :farm_code, pdn_region_id: :production_region_id } },
                                                   { parent_table: :production_regions, columns: %i[production_region_code], foreign_key: :production_region_id, flatten_columns: { production_region_code: :production_region_code } },
                                                   { parent_table: :pucs, columns: %i[puc_code], foreign_key: :puc_id, flatten_columns: { puc_code: :puc_code } },
                                                   { parent_table: :orchards, columns: %i[orchard_code], foreign_key: :orchard_id, flatten_columns: { orchard_code: :orchard_code } },
                                                   { parent_table: :cultivars, columns: %i[cultivar_code cultivar_name commodity_id], foreign_key: :cultivar_id, flatten_columns: { cultivar_code: :cultivar_code, cultivar_name: :cultivar_name, commodity_id: :commodity_id } },
                                                   { parent_table: :cultivar_groups, columns: %i[cultivar_group_code], foreign_key: :cultivar_group_id, flatten_columns: { cultivar_group_code: :cultivar_group_code } },
                                                   { parent_table: :commodities, columns: %i[code description], foreign_key: :commodity_id, flatten_columns: { code: :commodity_code, description: :commodity_description } },
                                                   { parent_table: :standard_pack_codes, columns: %i[standard_pack_code], foreign_key: :standard_pack_code_id, flatten_columns: { standard_pack_code: :standard_pack_code } },
                                                   { parent_table: :marketing_varieties, columns: %i[marketing_variety_code], foreign_key: :marketing_variety_id, flatten_columns: { marketing_variety_code: :marketing_variety_code } },
                                                   { parent_table: :grades, columns: %i[grade_code], foreign_key: :grade_id, flatten_columns: { grade_code: :grade_code } }],
                                   lookup_functions: [{ function: :fn_current_status, args: ['pallet_sequences', :id],  col_name: :status }])
      return nil if hash.nil?

      hash[:pallet_carton_quantity] = get(:pallets, hash[:pallet_id], :carton_quantity) || 0
      hash[:pallet_percentage] = hash[:pallet_carton_quantity].zero? ? 0 : (hash[:carton_quantity] / hash[:pallet_carton_quantity].to_f).round(3)
      hash[:nett_weight] = hash[:nett_weight].to_f.round(2)
      PalletSequenceFlat.new(hash)
    end

    def find_stock_item(stock_item_id, stock_type)
      return find_pallet(stock_item_id) if stock_type == AppConst::PALLET_STOCK_TYPE

      DB[:rmt_bins].where(id: stock_item_id).first
    end

    def update_stock_item(stock_item_id, upd, stock_type)
      return update_pallet(stock_item_id, upd) if stock_type == AppConst::PALLET_STOCK_TYPE

      DB[:rmt_bins].where(id: stock_item_id).update(upd)
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

    def carton_carton_label(carton_id)
      DB[:cartons].where(id: carton_id).get(:carton_label_id)
    end

    def carton_label_id_for_pallet_no(pallet_no)
      DB[:carton_labels].where(pallet_number: pallet_no.to_s).get(:id)
    end

    def pallet_exists?(pallet_number)
      exists?(:pallets, pallet_number: pallet_number)
    end

    def pallet_id_for_pallet_number(pallet_number)
      DB[:pallets].where(pallet_number: pallet_number).get(:id)
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

    # def get_pallet_by_carton_label_id(carton_label_id)
    #   pallet = DB["select p.pallet_number
    #       from pallets p
    #       join pallet_sequences ps on p.id = ps.pallet_id
    #       join cartons c on c.id = ps.scanned_from_carton_id
    #       join carton_labels cl on cl.id = c.carton_label_id
    #       where cl.id = ?", carton_label_id].first
    #   return pallet[:pallet_number] unless pallet.nil?
    # end

    def get_pallet_by_carton_number(carton_number)
      return carton_number if AppConst::CARTON_EQUALS_PALLET

      pallet_sequence_id = get_value(:cartons, :pallet_sequence_id, carton_label_id: carton_number)
      get(:pallet_sequences, pallet_sequence_id, :pallet_number)
    end

    def production_run_stats(run_id)
      DB[:production_run_stats].where(production_run_id: run_id).map { |p| p[:bins_tipped] }.first
    end

    def get_oldest_pallet_sequence(pallet_id)
      query = <<~SQL
        SELECT i.inventory_code, tm.target_market_group_name, g.grade_code, m.mark_code,fs.size_reference, sp.standard_pack_code, sf.size_count_value
        ,c.cultivar_name, cg.cultivar_group_code, s.*
        FROM pallet_sequences s
        JOIN inventory_codes i ON i.id = s.inventory_code_id
        JOIN target_market_groups tm on tm.id=s.packed_tm_group_id
        JOIN fruit_size_references fs on fs.id=s.fruit_size_reference_id
        JOIN standard_pack_codes sp on sp.id=s.standard_pack_code_id
        JOIN std_fruit_size_counts sf on sf.id=s.std_fruit_size_count_id
        JOIN grades g on g.id=s.grade_id
        JOIN marks m on m.id=s.mark_id
        JOIN cultivars c on c.id=s.cultivar_id
        JOIN cultivar_groups cg on cg.id=s.cultivar_group_id
        WHERE s.pallet_id = ?
        ORDER BY s.pallet_sequence_number ASC
      SQL
      DB[query, pallet_id].first
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
      upd = "UPDATE pallet_sequences SET verified=true,verified_at='#{Time.now}',verified_by='#{params[:verified_by]}',verification_result = '#{params[:verification_result]}', verification_passed=#{params[:verification_result] != 'failed'}, pallet_verification_failure_reason_id = #{(params[:verification_result] != 'failed' ? 'Null' : "'#{params[:verification_failure_reason]}'")} #{nett_weight_upd} WHERE id = #{pallet_sequence_id};"
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

    def find_personnel_identifiers_by_palletizer_identifier(palletizer_identifier)
      DB[:personnel_identifiers].where(identifier: palletizer_identifier).get(:id)
    end

    def carton_attributes(carton_id)
      query = <<~SQL
        SELECT i.inventory_code, tm.target_market_group_name, g.grade_code, m.mark_code,fs.size_reference,
               sp.standard_pack_code, sf.size_count_value ,clt.cultivar_name, cg.cultivar_group_code, c.*
        FROM cartons c
        JOIN inventory_codes i ON i.id = c.inventory_code_id
        JOIN target_market_groups tm on tm.id = c.packed_tm_group_id
        JOIN fruit_size_references fs on fs.id = c.fruit_size_reference_id
        JOIN standard_pack_codes sp on sp.id = c.standard_pack_code_id
        JOIN std_fruit_size_counts sf on sf.id = c.std_fruit_size_count_id
        JOIN grades g on g.id = c.grade_id
        JOIN marks m on m.id = c.mark_id
        JOIN cultivars clt on clt.id = c.cultivar_id
        JOIN cultivar_groups cg on cg.id = c.cultivar_group_id
        WHERE c.id = ?
      SQL
      DB[query, carton_id].first
    end

    def new_sequence?(carton_id, pallet_id)
      matching_sequences = matching_sequence_for_carton(carton_id, pallet_id)
      matching_sequences.nil? ? true : false
    end

    def matching_sequence_for_carton(carton_id, pallet_id)
      carton_rejected_fields = %i[id carton_label_id pallet_number product_resource_allocation_id fruit_sticker_pm_product_id
                                  gross_weight nett_weight sell_by_code pallet_label_name pick_ref phc packing_method_id
                                  palletizer_identifier_id pallet_sequence_id created_at updated_at personnel_identifier_id contract_worker_id
                                  palletizing_bay_resource_id is_virtual]
      attrs = find_hash(:cartons, carton_id).reject { |k, _| carton_rejected_fields.include?(k) }
      DB[:pallet_sequences].where(pallet_id: pallet_id).where(attrs).get(:id)
    end
  end
end
