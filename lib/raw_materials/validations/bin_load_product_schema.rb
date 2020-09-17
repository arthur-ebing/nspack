# frozen_string_literal: true

module RawMaterialsApp
  BinLoadProductSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:bin_load_id).filled(:integer)
    required(:qty_bins).filled(:integer)
    required(:cultivar_group_id).filled(:integer)
    required(:cultivar_id).maybe(:integer)
    required(:rmt_container_material_type_id).maybe(:integer)
    required(:rmt_material_owner_party_role_id).maybe(:integer)
    required(:farm_id).maybe(:integer)
    required(:puc_id).maybe(:integer)
    required(:orchard_id).maybe(:integer)
    required(:rmt_class_id).maybe(:integer)
  end

  AllocateBinLoadProductSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:bin_ids).maybe(:array).each(:integer)
  end
end
