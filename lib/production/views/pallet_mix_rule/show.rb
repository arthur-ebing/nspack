# frozen_string_literal: true

module Production
  module Runs
    module PalletMixRule
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pallet_mix_rule, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Pallet Mix Rule'
              form.view_only!
              form.add_field :scope
              # form.add_field :production_run_id
              # form.add_field :pallet_id
              form.add_field :allow_tm_mix
              form.add_field :allow_grade_mix
              form.add_field :allow_size_ref_mix
              form.add_field :allow_pack_mix
              form.add_field :allow_std_count_mix
              form.add_field :allow_mark_mix
              form.add_field :allow_inventory_code_mix
              form.add_field :allow_cultivar_mix
              form.add_field :allow_cultivar_group_mix
              form.add_field :allow_puc_mix
              form.add_field :allow_orchard_mix
              form.add_field :packhouse_plant_resource_id
            end
          end

          layout
        end
      end
    end
  end
end
