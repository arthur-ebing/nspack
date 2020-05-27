# frozen_string_literal: true

module RawMaterialsApp
  BinLoadProductSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:bin_load_id, :integer).filled(:int?)
    required(:qty_bins, :integer).filled(:int?)
    required(:cultivar_id, :integer).maybe(:int?)
    required(:cultivar_group_id, :integer).maybe(:int?)
    required(:rmt_container_material_type_id, :integer).maybe(:int?)
    required(:rmt_material_owner_party_role_id, :integer).maybe(:int?)
    required(:farm_id, :integer).maybe(:int?)
    required(:puc_id, :integer).maybe(:int?)
    required(:orchard_id, :integer).maybe(:int?)
    required(:rmt_class_id, :integer).maybe(:int?)
  end

  AllocateBinLoadProductSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:bin_ids, Types::IntArray).filled { each(:int?) }
  end
end
