# frozen_string_literal: true

module MesscadaApp
  class HrRepo < BaseRepo
    def create_personnel_identifier(res)
      hw_type = if res[:card_reader]
                  'rfid-rdr'
                else
                  'rfid-usb'
                end
      DB[:personnel_identifiers].insert_conflict
                                .insert(identifier: res[:value],
                                        hardware_type: hw_type)
    end

    def contract_worker_name(personnel_identifier)
      personnel_identifier_id = DB[:personnel_identifiers].where(identifier: personnel_identifier).get(:id)
      return nil if personnel_identifier_id.nil?

      id = DB[:contract_workers].where(personnel_identifier_id: personnel_identifier_id).get(:id)
      DB.get(Sequel.function(:fn_contract_worker_name, id))
    end

    def contract_worker_name_by_no(personnel_number)
      id = DB[:contract_workers].where(personnel_number: personnel_number).get(:id)
      DB.get(Sequel.function(:fn_contract_worker_name, id))
    end

    def contract_worker_ids(personnel_identifier)
      DB[:personnel_identifiers]
        .join(:contract_workers, personnel_identifier_id: :id)
        .where(identifier: personnel_identifier)
        .select(Sequel[:contract_workers][:id].as(:contract_worker_id), :personnel_identifier_id, :personnel_number)
        .first
    end

    def personnel_identifier_id_from_device_identifier(identifier)
      DB[:personnel_identifiers].where(identifier: identifier).get(:id)
    end

    def contract_worker_id_from_personnel_id(personnel_identifier_id)
      DB[:contract_workers].where(personnel_identifier_id: personnel_identifier_id).get(:id)
    end

    def active_group_incentive_id(system_resource_id)
      DB[:group_incentives]
        .where(system_resource_id: system_resource_id, active: true)
        .get(:id)
    end
  end
end
