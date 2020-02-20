# frozen_string_literal: true

module ProductionApp
  class HumanResourcesRepo < BaseRepo
    build_for_select :shift_exceptions,
                     label: :remarks,
                     value: :id,
                     no_active_check: true,
                     order_by: :remarks

    crud_calls_for :shifts, name: :shift, wrapper: Shift
    crud_calls_for :shift_exceptions, name: :shift_exception, wrapper: ShiftException

    def find_shift(id)
      find_with_association(:shifts, id,
                            wrapper: Shift,
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
                            wrapper: ShiftException,
                            lookup_functions: [{ function: :fn_contract_worker_name,
                                                 args: [:contract_worker_id],
                                                 col_name: :contract_worker_name }])
    end

    def for_select_contract_workers_for_shift(shift_id)
      emp_type_id = DB[:shift_types].where(
        id: DB[:shifts].where(
          id: shift_id
        ).get(:shift_type_id)
      ).get(:employment_type_id)
      if emp_type_id
        MasterfilesApp::HumanResources.new.for_select_contract_workers(where: { employment_type_id: emp_type_id }).map do |r|
          [DB['SELECT fn_contract_worker_name(?)', r[1]].single_value, r[1]]
        end
      else
        []
      end
    end

    def create_shift(attrs)
      date = attrs[:date].strftime('%Y%m%d')
      shift_type = DB[:shift_types].where(id: attrs[:shift_type_id])
      start_hr = shift_type.get(:start_hour)
      end_hr = shift_type.get(:end_hour)

      attrs[:start_date_time] = Time.parse("#{date} #{start_hr}")
      attrs[:end_date_time] = Time.parse("#{date} #{end_hr}")
      DB[:shifts].insert(attrs)
    end
  end
end
