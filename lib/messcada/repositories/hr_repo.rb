# frozen_string_literal: true

module MesscadaApp
  class HrRepo < BaseRepo
    def create_personnel_identifier(res)
      hw_type = if res[:card_reader]
                  'rfid'
                else
                  'usb'
                end
      DB[:personnel_identifiers].insert_conflict(target: :identifier,
                                                 update: { hardware_type: hw_type })
                                .insert(identifier: res[:value],
                                        hardware_type: hw_type)
    end
  end
end
