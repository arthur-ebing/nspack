# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :govt_inspection_sheets,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_for_select :govt_inspection_pallets,
                     label: :failure_remarks,
                     value: :id,
                     order_by: :failure_remarks
    build_for_select :govt_inspection_api_results,
                     label: :upn_number,
                     value: :id,
                     order_by: :upn_number
    build_for_select :govt_inspection_pallet_api_results,
                     label: :id,
                     value: :id,
                     order_by: :id

    build_inactive_select :govt_inspection_sheets,
                          label: :id,
                          value: :id,
                          order_by: :id
    build_inactive_select :govt_inspection_pallets,
                          label: :failure_remarks,
                          value: :id,
                          order_by: :failure_remarks
    build_inactive_select :govt_inspection_api_results,
                          label: :upn_number,
                          value: :id,
                          order_by: :upn_number
    build_inactive_select :govt_inspection_pallet_api_results,
                          label: :id,
                          value: :id,
                          order_by: :id

    crud_calls_for :govt_inspection_sheets, name: :govt_inspection_sheet, wrapper: GovtInspectionSheet
    crud_calls_for :govt_inspection_pallets, name: :govt_inspection_pallet, wrapper: GovtInspectionPallet
    crud_calls_for :govt_inspection_api_results, name: :govt_inspection_api_result, wrapper: GovtInspectionApiResult
    crud_calls_for :govt_inspection_pallet_api_results, name: :govt_inspection_pallet_api_result, wrapper: GovtInspectionPalletApiResult
    crud_calls_for :vehicle_jobs, name: :vehicle_job, wrapper: VehicleJob
    crud_calls_for :vehicle_job_units, name: :vehicle_job_unit, wrapper: VehicleJobUnit

    def find_govt_inspection_sheet(id)
      find_with_association(:govt_inspection_sheets,
                            id,
                            parent_tables: [{ parent_table: :target_market_groups,
                                              columns: %i[target_market_group_name],
                                              foreign_key: :packed_tm_group_id,
                                              flatten_columns: { target_market_group_name: :packed_tm_group } },
                                            { parent_table: :destination_regions,
                                              columns: %i[destination_region_name],
                                              foreign_key: :destination_region_id,
                                              flatten_columns: { destination_region_name: :region_name } }],
                            lookup_functions: [{ function: :fn_consignment_note_number,
                                                 args: [id],
                                                 col_name: :consignment_note_number }],
                            wrapper: GovtInspectionSheet)
    end

    def for_select_destination_regions(active = true, where: nil)
      ds = DB[:destination_regions].join(:destination_regions_tm_groups, destination_region_id: :id).distinct
      ds = ds.where(active: active)
      ds = ds.where(where) unless where.nil?
      ds.select_map(%i[destination_region_name id])
    end

    def for_select_inactive_destination_regions(where: nil)
      for_select_destination_regions(false, where: where)
    end

    def validate_govt_inspection_sheet_inspect_params(id)
      pallet_ids = DB[:govt_inspection_pallets].where(govt_inspection_sheet_id: id, inspected: false).select_map(:pallet_id)
      pallet_numbers = DB[:pallets].where(id: pallet_ids).select_map(:pallet_number).join(', ')
      return failed_response("Pallet: #{pallet_numbers}, results not captured.") unless pallet_numbers.empty?

      ok_response
    end

    def last_record(column)
      DB[:govt_inspection_sheets].reverse(:id).limit(1).get(column)
    end

    def find_govt_inspection_pallet_flat(id)
      find_with_association(:govt_inspection_pallets,
                            id,
                            parent_tables: [{ parent_table: :inspection_failure_reasons,
                                              columns: %i[failure_reason description main_factor secondary_factor],
                                              foreign_key: :failure_reason_id,
                                              flatten_columns: { failure_reason: :failure_reason,
                                                                 description: :description,
                                                                 main_factor: :main_factor,
                                                                 secondary_factor: :secondary_factor } }],
                            lookup_functions: [{ function: :fn_current_status,
                                                 args: ['pallets', :pallet_id],
                                                 col_name: :status }],
                            wrapper: GovtInspectionPalletFlat)
    end

    def exists_on_inspection_sheet(pallet_numbers)
      ds = DB[:govt_inspection_pallets]
      ds = ds.join(:pallets, id: Sequel[:govt_inspection_pallets][:pallet_id])
      ds = ds.join(:govt_inspection_sheets, id: Sequel[:govt_inspection_pallets][:govt_inspection_sheet_id])
      ds = ds.where(cancelled: false, pallet_number: pallet_numbers)
      ds.select_map(:pallet_number)
    end

    def selected_pallets(pallet_sequence_ids)
      select_values(:pallet_sequences, :pallet_id, id: pallet_sequence_ids)
    end

    def load_vehicle_job_units(vehicle_job_id)
      DB[:vehicle_job_units].where(vehicle_job_id: vehicle_job_id).update(loaded_at: Time.now)
    end

    def get_vehicle_job_units(vehicle_job_id)
      # DB[:vehicle_job_units].where(vehicle_job_id: vehicle_job_id)
      query = <<~SQL
        SELECT u.*, p.pallet_number
        FROM  vehicle_job_units u
        JOIN pallets p on p.id=u.stock_item_id
        WHERE u.vehicle_job_id = ?
      SQL
      DB[query, vehicle_job_id]
    end

    def get_vehicle_job_location(vehicle_job_id)
      query = <<~SQL
        SELECT l.location_long_code
        FROM  vehicle_jobs v
        JOIN locations l on l.id=v.planned_location_to_id
        WHERE v.id = ?
      SQL
      DB[query, vehicle_job_id].select_map(:location_long_code).first
    end

    def get_tripsheet_pallet_ids(vehicle_job_id)
      DB[:vehicle_job_units].where(vehicle_job_id: vehicle_job_id).select_map(:stock_item_id)
    end

    def offloaded_vehicle_pallets(govt_inspection_sheet_id)
      query = <<~SQL
        SELECT count(u.id) as num_offloaded_plts
        FROM vehicle_jobs v
        JOIN vehicle_job_units u on u.vehicle_job_id = v.id
        WHERE v.govt_inspection_sheet_id = ? and u.offloaded_at is not null
      SQL
      DB[query, govt_inspection_sheet_id].first[:num_offloaded_plts]
    end

    def find_vehicle_job_unit_by(key, val)
      hash = DB[:vehicle_job_units].where(Sequel[:vehicle_job_units][key] => val).first
      return nil if hash.nil?

      VehicleJobUnit.new(hash)
    end

    def delete_vehicle_job(vehicle_job_id)
      DB[:vehicle_job_units].where(vehicle_job_id: vehicle_job_id).delete
      DB[:vehicle_jobs].where(id: vehicle_job_id).delete
    end

    def refresh_tripsheet?(govt_inspection_sheet_id)
      vehicle_job_id = get_id(:vehicle_jobs, govt_inspection_sheet_id: govt_inspection_sheet_id)
      govt_inspection_pallets = all_hash(:govt_inspection_pallets,  govt_inspection_sheet_id: govt_inspection_sheet_id)
      tripsheet_pallets = get_vehicle_job_units(vehicle_job_id)

      tripsheet_pallets.map { |p| p[:stock_item_id] }.sort != govt_inspection_pallets.map { |p| p[:pallet_id] }.sort
    end

    def get_vehicle_jobs_pallets(vehicle_job_id)
      query = <<~SQL
        SELECT p.pallet_number
        FROM vehicle_jobs v
        JOIN vehicle_job_units u on u.vehicle_job_id = v.id
        JOIN pallets p on p.id = u.stock_item_id
        WHERE v.id = ?
      SQL
      DB[query, vehicle_job_id].map { |p| p[:pallet_number] }
    end

    def tripsheet_offload_complete?(vehicle_job_id)
      tripsheet_pallets = get_vehicle_job_units(vehicle_job_id)
      (tripsheet_pallets.all.find_all { |p| !p[:offloaded_at] }).empty?
    end

    def refresh_to_complete_offload?(govt_inspection_sheet_id)
      query = <<~SQL
        SELECT EXISTS(SELECT u.id
        FROM  vehicle_job_units u
        JOIN pallets p on p.id=u.stock_item_id
        JOIN govt_inspection_pallets g on g.pallet_id=p.id
        WHERE g.govt_inspection_sheet_id = ?
          AND u.offloaded_at IS NULL)
      SQL
      !DB[query, govt_inspection_sheet_id].single_value
    end
  end
end
