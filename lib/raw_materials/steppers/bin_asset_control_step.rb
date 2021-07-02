# frozen_string_literal: true

module RawMaterialsApp
  class BinAssetControlStep < BaseStep
    include Crossbeams::Responses

    def initialize(user, ip, repo)
      super(user, :bin_asset_control, ip)
      @repo = repo
    end

    def for_select_bin_sets
      for_select = []
      bin_sets.each do |r|
        owner_bin_type = @repo.find_owner_bin_type(r[:rmt_material_owner_party_role_id], r[:rmt_container_material_type_id])
        combined_id = "#{r[:rmt_material_owner_party_role_id]}_#{r[:rmt_container_material_type_id]}"
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

    def add_bin_set(set)
      sets = bin_sets
      sets.each do |r|
        same_owner = r[:rmt_material_owner_party_role_id] == set[:rmt_material_owner_party_role_id]
        same_type = r[:rmt_container_material_type_id] == set[:rmt_container_material_type_id]
        next unless same_owner && same_type

        return validation_failed_response(OpenStruct.new(messages: { base: ['This combination already exists.'] }))
      end
      sets << set
      write(read.merge(bin_sets: sets.uniq))
      success_response('ok', bin_sets)
    end

    def remove_bin_set(combined_id)
      sets = bin_sets
      owner_id, type_id = combined_id.split('_')
      sets.reject! { |r| r[:rmt_material_owner_party_role_id] == owner_id && r[:rmt_container_material_type_id] == type_id }
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
