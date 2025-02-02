# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtCode
      class New
        def self.call(rmt_variant_id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:rmt_code, :new, form_values: form_values, rmt_variant_id: rmt_variant_id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Rmt Code'
              form.action "/masterfiles/raw_materials/rmt_variants/#{rmt_variant_id}/rmt_codes"
              form.remote! if remote
              form.add_field :rmt_variant_id
              form.add_field :rmt_handling_regime_id
              form.add_field :rmt_code
              form.add_field :description
              form.add_field :legacy_code
            end
          end
        end
      end
    end
  end
end
