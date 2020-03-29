# frozen_string_literal: true

module Production
  module Runs
    module PalletMixRule
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pallet_mix_rule, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Pallet Mix Rule'
              form.action "/production/runs/pallet_mix_rules/#{id}"
              form.remote!
              form.method :update
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
            end
          end

          layout
        end
      end
    end
  end
end
