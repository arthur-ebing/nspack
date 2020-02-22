# frozen_string_literal: true

module MasterfilesApp
  class HumanResourcesRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :employment_types,
                     label: :employment_type_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :employment_type_code

    crud_calls_for :employment_types, name: :employment_type, wrapper: EmploymentType

    build_for_select :contract_types,
                     label: :contract_type_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :contract_type_code

    crud_calls_for :contract_types, name: :contract_type, wrapper: ContractType

    build_for_select :wage_levels,
                     label: :description,
                     value: :id,
                     no_active_check: true,
                     order_by: :description

    crud_calls_for :wage_levels, name: :wage_level, wrapper: WageLevel

    build_for_select :contract_workers,
                     label: :first_name,
                     value: :id,
                     order_by: :first_name
    build_inactive_select :contract_workers,
                          label: :first_name,
                          value: :id,
                          order_by: :first_name

    crud_calls_for :contract_workers, name: :contract_worker, wrapper: ContractWorker

    build_for_select :shift_types,
                     label: :id,
                     value: :id,
                     no_active_check: true,
                     order_by: :id

    crud_calls_for :shift_types, name: :shift_type, wrapper: ShiftType

    build_for_select :shifts,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :shifts,
                          label: :id,
                          value: :id,
                          order_by: :id

    crud_calls_for :shifts, name: :shift, wrapper: ProductionApp::Shift

    build_for_select :shift_exceptions,
                     label: :remarks,
                     value: :id,
                     no_active_check: true,
                     order_by: :remarks

    crud_calls_for :shift_exceptions, name: :shift_exception, wrapper: ProductionApp::ShiftException

    crud_calls_for :personnel_identifiers, name: :personnel_identifier, wrapper: PersonnelIdentifier

    def for_select_unallocated_contract_workers
      DB[:contract_workers]
        .where(active: true, personnel_identifier_id: nil)
        .select(Sequel.function(:fn_contract_worker_name, :id), :id)
        .map { |rec| [rec[:fn_contract_worker_name], rec[:id]] }
    end

    def find_contract_worker(id)
      find_with_association(:contract_workers, id,
                            wrapper: ContractWorker,
                            parent_tables: [{ parent_table: :employment_types,
                                              columns: [:employment_type_code],
                                              flatten_columns: { employment_type_code: :employment_type_code } },
                                            { parent_table: :contract_types,
                                              columns: [:contract_type_code],
                                              flatten_columns: { contract_type_code: :contract_type_code } },
                                            { parent_table: :wage_levels,
                                              columns: [:wage_level],
                                              flatten_columns: { wage_level: :wage_level } }],
                            lookup_functions: [{ function: :fn_contract_worker_name,
                                                 args: [:id],
                                                 col_name: :contract_worker_name }])
    end

    def find_contract_worker_id_by_identifier_id(personnel_identifier_id)
      DB[:contract_workers]
        .where(personnel_identifier_id: personnel_identifier_id)
        .get(:id)
    end

    def find_contract_worker_by_identifier_id(personnel_identifier_id)
      id = find_contract_worker_id_by_identifier_id(personnel_identifier_id)
      find_contract_worker(id)
    end

    def find_shift_type(id)
      find_with_association(:shift_types, id,
                            wrapper: ShiftType,
                            lookup_functions: [{ function: :fn_shift_type_code,
                                                 args: [:id],
                                                 col_name: :shift_type_code }],
                            parent_tables: [{ parent_table: :employment_types,
                                              columns: [:employment_type_code],
                                              flatten_columns: { employment_type_code: :employment_type_code } },
                                            { parent_table: :plant_resources,
                                              columns: [:plant_resource_code],
                                              flatten_columns: { plant_resource_code: :plant_resource_code } }])
    end

    def find_shift(id)
      find_with_association(:shifts, id,
                            wrapper: ProductionApp::Shift,
                            parent_tables: [{
                              parent_table: :employment_types,
                              columns: [:code],
                              flatten_columns: { code: :employment_type_code }
                            }],
                            lookup_functions: [{ function: :fn_shift_type_code,
                                                 args: [:shift_type_id],
                                                 col_name: :shift_type_code }])
    end

    def find_shift_exception(id)
      find_with_association(:shift_exceptions, id,
                            wrapper: ProductionApp::ShiftException,
                            lookup_functions: [{ function: :fn_contract_worker_name,
                                                 args: [:contract_worker_id],
                                                 col_name: :contract_worker_name }])
    end

    def for_select_plant_resources_for_ph_pr_id(ph_pr_id)
      type = where_hash(:plant_resource_types, plant_resource_type_code: Crossbeams::Config::ResourceDefinitions::LINE, active: true)
      return [] if type.nil?

      descendant_ids = DB[:tree_plant_resources].where(ancestor_plant_resource_id: ph_pr_id).select_map(:descendant_plant_resource_id)

      resource_repo = ProductionApp::ResourceRepo.new
      lines = resource_repo.for_select_plant_resources(where: { id: descendant_ids, plant_resource_type_id: type[:id] })
      [['Please choose', nil]] + lines
    end

    def create_shift_type(attrs)
      new_attrs = attrs.to_h
      ph_id = new_attrs.delete(:ph_plant_resource_id)
      new_attrs[:plant_resource_id] = (line_id = new_attrs.delete(:line_plant_resource_id)) ? line_id : ph_id
      create(:shift_types, new_attrs)
    end

    def similar_shift_type_hours(attrs)
      grouped = %w[D N]
      inc = grouped.include?(attrs[:day_night_or_custom])

      plant_resource_id = attrs[:line_plant_resource_id] || attrs[:ph_plant_resource_id]
      DB[:shift_types].where(
        plant_resource_id: plant_resource_id,
        employment_type_id: attrs[:employment_type_id],
        day_night_or_custom: inc ? grouped : 'C'
      ).map { |r| { start_hour: r[:start_hour], end_hour: r[:end_hour] } }
    end

    def for_select_shift_types_with_codes
      options = []
      for_select_shift_types.each do |st_id|
        options << [find_shift_type(st_id)&.shift_type_code, st_id]
      end
      options
    end

    def similar_shift_hours(attrs)
      DB[:shifts].where(
        shift_type_id: attrs[:shift_type_id]
      ).map { |r| { start_date_time: r[:start_date_time].strftime('%Y%m%d%H%M').to_i, end_date_time: r[:end_date_time].strftime('%Y%m%d%H%M').to_i } }
    end
  end
end
