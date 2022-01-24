# frozen_string_literal: true

module Production
  module Runs
    module PalletMixRule
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:pallet_mix_rule, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Pallet Mix Rule'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :scope
                  # col.add_field :production_run_id
                  # col.add_field :pallet_id
                  col.add_field :allow_puc_mix
                  col.add_field :allow_orchard_mix
                  col.add_field :allow_cultivar_group_mix
                  col.add_field :allow_cultivar_mix
                  col.add_field :allow_variety_mix
                  col.add_field :allow_std_count_mix
                  col.add_field :allow_size_ref_mix
                end
                row.column do |col|
                  col.add_field :packhouse_plant_resource_id
                  col.add_field :allow_tm_mix
                  col.add_field :allow_marketing_org_mix
                  col.add_field :allow_grade_mix
                  col.add_field :allow_pack_mix
                  col.add_field :allow_mark_mix
                  col.add_field :allow_inventory_code_mix
                  col.add_field :allow_sell_by_mix
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
