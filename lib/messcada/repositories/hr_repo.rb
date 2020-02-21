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
      id = DB[:personnel_identifiers].where(identifier: personnel_identifier).get(:id)
      DB.get(Sequel.function(:fn_contract_worker_name, id))
    end
  end
end
