# frozen_string_literal: true

module ProductionApp
  class HumanResourcesRepo < BaseRepo
    build_for_select :shift_exceptions,
                     label: :remarks,
                     value: :id,
                     no_active_check: true,
                     order_by: :remarks

    crud_calls_for :shifts, name: :shift, exclude: %i[create]
    crud_calls_for :shift_exceptions, name: :shift_exception

    def find_shift(id)
      hash = find_with_association(
        :shifts, id,
        parent_tables: [{ parent_table: :shift_types,
                          columns: [:employment_type_id],
                          flatten_columns: { employment_type_id: :employment_type_id } },
                        { parent_table: :employment_types,
                          foreign_key: :employment_type_id,
                          columns: [:employment_type_code],
                          flatten_columns: { employment_type_code: :employment_type_code } }],
        lookup_functions: [{ function: :fn_shift_type_code,
                             args: [:shift_type_id],
                             col_name: :shift_type_code }]
      )
      return nil if hash.nil?

      hash[:packer] = hash[:employment_type_code] == 'PACKERS'
      Shift.new(hash)
    end

    def find_shift_exception(id)
      find_with_association(:shift_exceptions, id,
                            wrapper: ShiftException,
                            lookup_functions: [{ function: :fn_contract_worker_name,
                                                 args: [:contract_worker_id],
                                                 col_name: :contract_worker_name }])
    end

    def for_select_contract_workers_for_shift(shift_id) # rubocop:disable Metrics/AbcSize
      emp_type_id = DB[:shift_types].where(
        id: DB[:shifts].where(
          id: shift_id
        ).get(:shift_type_id)
      ).get(:employment_type_id)
      cw_ids = DB[:shift_exceptions].where(shift_id: shift_id).select_map(:contract_worker_id)
      MasterfilesApp::HumanResourcesRepo.new.for_select_contract_workers(where: { employment_type_id: emp_type_id }).map do |r|
        next if cw_ids.include?(r[1])

        [DB['SELECT fn_contract_worker_name(?)', r[1]].single_value, r[1]]
      end
    end

    def for_select_contract_workers
      MasterfilesApp::HumanResourcesRepo.new.for_select_contract_workers.map do |r|
        [DB['SELECT fn_contract_worker_name(?)', r[1]].single_value, r[1]]
      end
    end

    def create_shift(attrs) # rubocop:disable Metrics/AbcSize
      attrs = attrs.to_h
      date = attrs.delete(:date)

      shift_type = DB[:shift_types].where(id: attrs[:shift_type_id])
      start_hr = shift_type.get(:start_hour)
      end_hr = shift_type.get(:end_hour)

      attrs[:start_date_time] = Time.parse("#{date} #{start_hr}")
      end_date = end_hr < start_hr ? date + 1 : date
      attrs[:end_date_time] = Time.parse("#{end_date} #{end_hr}") - 59

      check_if_shift_overlap!(attrs)
      DB[:shifts].insert(attrs)
    end

    def check_if_shift_overlap!(params) # rubocop:disable Metrics/AbcSize
      args = params.to_h
      shift_type = DB[:shift_types].where(id: args[:shift_type_id])
      similar_shift_type_ids = DB[:shift_types]
                               .where(plant_resource_id: shift_type.get(:plant_resource_id),
                                      employment_type_id: shift_type.get(:employment_type_id))
                               .select_map(:id)

      shifts = DB[:shifts]
               .where(shift_type_id: similar_shift_type_ids)
               .where { start_date_time >= (args[:start_date_time] - (24 * 60 * 60)) }
               .select_map(%i[id start_date_time end_date_time])
      shifts.each do |id, start_date_time, end_date_time|
        next if id == args[:id]
        next unless (args[:start_date_time]).between?(start_date_time, end_date_time) || (args[:end_date_time]).between?(start_date_time, end_date_time)

        shift = find_shift(id)
        message = "Shift overlaps with #{shift.shift_type_code} from #{shift.start_date_time.strftime('%Y-%m-%d %H:%M:%S')} to #{shift.end_date_time.strftime('%Y-%m-%d %H:%M:%S')}"
        raise Crossbeams::InfoError, message
      end
    end

    def find_group_incentives_with(contract_worker_id)
      query = <<~SQL
        SELECT id FROM group_incentives WHERE contract_worker_ids @> ARRAY[#{contract_worker_id}];
      SQL
      DB[query].all.map { |r| r[:id] }
    end
  end
end
