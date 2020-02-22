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
      id = DB[:contract_workers].where(personnel_identifier_id: personnel_identifier_id).get(:id)
      DB.get(Sequel.function(:fn_contract_worker_name, id))
    end

    def contract_worker_ids(personnel_identifier)
      DB[:personnel_identifiers]
        .join(:contract_workers, personnel_identifier_id: :id)
        .where(identifier: personnel_identifier)
        .select(Sequel[:contract_workers][:id].as(:contract_worker_id), :personnel_identifier_id)
        .first
    end
  end
end
