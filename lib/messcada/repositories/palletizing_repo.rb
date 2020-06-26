# frozen_string_literal: true

module MesscadaApp
  class PalletizingRepo < BaseRepo # rubocop:disable Metrics/ClassLength
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

    def find_palletizing_bay_state(id)
      hash = find_with_association(:palletizing_bay_states,
                                   id,
                                   parent_tables: [{ parent_table: :pallet_sequences,
                                                     columns: [:pallet_id],
                                                     flatten_columns: { pallet_id: :pallet_id } }])
      return nil if hash.nil?

      PalletizingBayStateFlat.new(hash)
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

    def completed_pallet?(carton_id)
      query = <<~SQL
        SELECT EXISTS(
          SELECT pallets.id FROM pallets
          JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
          JOIN cartons ON cartons.pallet_sequence_id = pallet_sequences.id
          WHERE cartons.id = #{carton_id}
          AND (pallets.in_stock OR pallets.build_status = '#{AppConst::PALLET_FULL_BUILD_STATUS}')
        )
      SQL
      DB[query].single_value
    end

    def closed_production_run?(carton_id)
      query = <<~SQL
        SELECT EXISTS(
          SELECT production_runs.id FROM production_runs
          JOIN cartons on cartons.production_run_id = production_runs.id
          WHERE cartons.id = #{carton_id}
          AND production_runs.closed
        )
      SQL
      DB[query].single_value
    end

    def carton_of_other_bay?(carton_id)
      query = <<~SQL
        SELECT EXISTS(
          SELECT pallet_sequence_id FROM cartons
          WHERE id = #{carton_id}
            AND	pallet_sequence_id IN (SELECT DISTINCT pallet_sequence_id FROM palletizing_bay_states)
        )
      SQL
      DB[query].single_value
    end

    def carton_palletizing_bay_state(carton_id)
      DB[:palletizing_bay_states]
        .where(pallet_sequence_id: DB[:cartons]
                                       .where(id: carton_id)
                                       .select(:pallet_sequence_id))
        .get(:id)
    end

    def valid_pallet_carton?(carton_id)
      query = <<~SQL
        SELECT EXISTS(
          SELECT pallets.id FROM pallets
          JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
          JOIN cartons ON cartons.pallet_sequence_id = pallet_sequences.id
          WHERE cartons.id = #{carton_id}
          --AND pallets.palletized
          --AND cartons.scrapped
          AND (NOT pallets.shipped OR NOT pallets.scrapped)
        )
      SQL
      DB[query].single_value
    end

    def find_pallet_by_carton_id(carton_id)
      DB[:pallet_sequences]
        .join(:cartons, pallet_sequence_id: :id)
        .where(Sequel[:cartons][:id] => carton_id)
        .get(:pallet_id)
    end

    def pallet_oldest_carton(pallet_id)
      query = <<~SQL
        SELECT cartons.pallet_sequence_id, cartons.id AS carton_id
        FROM pallet_sequences
        JOIN cartons ON cartons.pallet_sequence_id = pallet_sequences.id
        WHERE pallet_sequences.pallet_id = ?
        ORDER BY pallet_sequences.id, pallet_sequences.pallet_sequence_number ASC
      SQL
      DB[query, pallet_id].first
    end
  end
end
