# frozen_string_literal: true

module RawMaterialsApp
  class EmptyBinControlStep < BaseStep
    def initialize(user, ip, repo)
      super(user, :empty_bin_control, ip)
      @repo = repo
    end

    def for_select_bin_sets
      for_select = []
      bin_sets.each do |r|
        owner_bin_type = @repo.find_owner_bin_type(r[:rmt_container_material_owner_id], r[:rmt_container_material_type_id])
        combined_id = "#{r[:rmt_container_material_owner_id]}_#{r[:rmt_container_material_type_id]}"
        name = "#{owner_bin_type.owner_party_name}, #{owner_bin_type.container_material_type_code}, QTY: #{r[:quantity_bins]}"
        for_select << [name, combined_id]
      end
      for_select
    end

    def bin_sets
      current_step[:bin_sets] ||= []
    end

    def bin_sets=(bin_sets)
      write(read.merge(bin_sets: bin_sets))
    end

    def add_bin_set(set) # rubocop:disable Metrics/AbcSize
      sets = bin_sets
      added = false
      sets.each do |r|
        same_owner = r[:rmt_container_material_owner_id] == set[:rmt_container_material_owner_id]
        same_type = r[:rmt_container_material_type_id] == set[:rmt_container_material_type_id]
        next unless same_owner && same_type

        qty = r[:quantity_bins].to_i + set[:quantity_bins].to_i
        r[:quantity_bins] = qty
        added = true
      end
      sets << set unless added
      write(read.merge(bin_sets: sets.uniq))
    end

    def remove_bin_set(set)
      sets = bin_sets
      owner_id, type_id = set[:empty_bin_type_ids].split('_')
      sets.reject! { |r| r[:rmt_container_material_owner_id] == owner_id && r[:rmt_container_material_type_id] == type_id }
      self.bin_sets = sets
    end

    def reset
      clear
      write({})
    end

    private

    def current_step
      @current_step ||= read || {}
    end
  end
end
