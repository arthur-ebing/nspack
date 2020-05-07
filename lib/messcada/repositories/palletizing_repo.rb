# frozen_string_literal: true

module MesscadaApp
  class PalletizingRepo < BaseRepo
    build_for_select :palletizing_bay_states,
                     label: :palletizing_robot_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :palletizing_robot_code

    crud_calls_for :palletizing_bay_states, name: :palletizing_bay_state, wrapper: PalletizingBayState

    def palletizing_bay_state_by_robot_scanner(device, scanner)
      state = where(:palletizing_bay_states,
                    MesscadaApp::PalletizingBayState,
                    palletizing_robot_code: device,
                    scanner_code: scanner)
      state.nil? ? create_state(device, scanner) : state
    end

    def create_state(device, scanner)
      id = DB[:palletizing_bay_states].insert(palletizing_robot_code: device,
                                              scanner_code: scanner,
                                              palletizing_bay_resource_id: nil,
                                              current_state: 'empty',
                                              pallet_sequence_id: nil,
                                              determining_carton_id: nil,
                                              last_carton_id: nil)
      find_palletizing_bay_state(id)
    end

    def current_palletizing_bay_attributes(palletizing_bay_state_id, external_attributes = {})
      query = <<~SQL
        SELECT COALESCE(plant_resources.plant_resource_code, palletizing_robot_code || ': ' || scanner_code) AS bay_name,
        current_state,
        pallet_sequences.pallet_number,
        pallet_sequences.carton_quantity,
        cartons_per_pallet.cartons_per_pallet
        FROM palletizing_bay_states
        LEFT JOIN plant_resources ON plant_resources.id = palletizing_bay_resource_id
        LEFT JOIN pallet_sequences ON pallet_sequences.id = pallet_sequence_id
        LEFT JOIN cartons ON cartons.id = determining_carton_id
        LEFT JOIN cartons_per_pallet ON cartons_per_pallet.id = cartons.cartons_per_pallet_id
        WHERE palletizing_bay_states.id = ?
      SQL
      DB[query, palletizing_bay_state_id].first.merge(external_attributes)
    end
  end
end
