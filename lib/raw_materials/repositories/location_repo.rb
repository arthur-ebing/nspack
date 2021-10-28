# frozen_string_literal: true

module RawMaterialsApp
  class LocationRepo < BaseRepo
    def find_location(id)
      Location.new(DB[:locations].where(id: id).select(:id, :location_long_code, Sequel.function(:fn_current_status, 'locations', id).as(:current_status)).first)
    end

    def bin_ids_for_location(id)
      DB[:rmt_bins].where(location_id: id).select_map(:id)
    end
  end
end
