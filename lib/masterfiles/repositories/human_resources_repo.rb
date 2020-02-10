# frozen_string_literal: true

module MasterfilesApp
  class HumanResourcesRepo < BaseRepo
    build_for_select :employment_types,
                     label: :code,
                     value: :id,
                     no_active_check: true,
                     order_by: :code

    crud_calls_for :employment_types, name: :employment_type, wrapper: EmploymentType

    build_for_select :contract_types,
                     label: :code,
                     value: :id,
                     no_active_check: true,
                     order_by: :code

    crud_calls_for :contract_types, name: :contract_type, wrapper: ContractType

    build_for_select :wage_levels,
                     label: :description,
                     value: :id,
                     no_active_check: true,
                     order_by: :description

    crud_calls_for :wage_levels, name: :wage_level, wrapper: WageLevel

    build_for_select :contract_workers,
                     label: :full_names,
                     value: :id,
                     order_by: :full_names
    build_inactive_select :contract_workers,
                          label: :full_names,
                          value: :id,
                          order_by: :full_names

    crud_calls_for :contract_workers, name: :contract_worker, wrapper: ContractWorker

    build_for_select :shift_types,
                     label: :id,
                     value: :id,
                     no_active_check: true,
                     order_by: :id

    crud_calls_for :shift_types, name: :shift_type, wrapper: ShiftType

    def find_contract_worker(id)
      find_with_association(:contract_workers, id,
                            wrapper: ContractWorker,
                            parent_tables: [{ parent_table: :employment_types,
                                              columns: [:code],
                                              flatten_columns: { code: :employer_type_code } },
                                            { parent_table: :contract_types,
                                              columns: [:code],
                                              flatten_columns: { code: :contract_type_code } },
                                            { parent_table: :wage_levels,
                                              columns: [:wage_level],
                                              flatten_columns: { wage_level: :wage_level } }])
    end

    def find_shift_type(id)
      find_with_association(:shift_types, id,
                            wrapper: ShiftType,
                            lookup_functions: [{ function: :fn_shift_type_code,
                                                 args: [:id],
                                                 col_name: :shift_type_code }],
                            parent_tables: [{ parent_table: :employment_types,
                                              columns: [:code],
                                              flatten_columns: { code: :employment_type_code } },
                                            { parent_table: :plant_resources,
                                              columns: [:plant_resource_code],
                                              flatten_columns: { plant_resource_code: :plant_resource_code } }])
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
      DB[:shift_types].where(
        plant_resource_id: attrs[:plant_resource_id],
        employment_type_id: attrs[:employment_type_id],
        day_night_or_custom: attrs[:day_night_or_custom]
      ).map { |r| { start_hour: r[:start_hour], end_hour: r[:end_hour] } }
    end
  end
end
