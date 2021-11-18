# frozen_string_literal: true

module RawMaterialsApp
  class LocationRepo < BaseRepo
    def find_location(id)
      Location.new(DB[:locations].where(id: id).select(:id, :location_long_code, Sequel.function(:fn_current_status, 'locations', id).as(:current_status)).first)
    end

    def bin_ids_for_location(id)
      DB[:rmt_bins].where(location_id: id).select_map(:id)
    end

    def create_location_coldroom_event(event_name, location_id, rmt_bin_ids)
      id = create(:location_coldroom_events, event_name: event_name, location_id: location_id)
      return if rmt_bin_ids.empty?

      # update all bins - append id to coldroom_events
      upd = <<~SQL
        UPDATE rmt_bins
        SET coldroom_events = array_append(coldroom_events, ?)
        WHERE id IN ?
      SQL
      DB[upd, id, rmt_bin_ids].update
    end

    def coldroom_events_for_bin(rmt_bin_id)
      query = <<~SQL
        SELECT location_coldroom_events.id, location_coldroom_events.event_name, location_coldroom_events.created_at,
          locations.location_long_code
        FROM location_coldroom_events
        JOIN locations ON locations.id = location_coldroom_events.location_id
        WHERE location_coldroom_events.id IN (SELECT UNNEST(rmt_bins.coldroom_events) FROM rmt_bins WHERE rmt_bins.id = ?)
        ORDER BY created_at DESC
      SQL
      rows = DB[query, rmt_bin_id].all
      cols = %i[event_name created_at location_long_code]
      heads = { created_at: 'Start at', location_long_code: 'in Location' }
      [rows, cols, heads]
    end
  end
end
