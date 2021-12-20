# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class ClassifyRawMaterial
        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:classify_raw_material, :classify_raw_material, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.remote! if remote
              form.caption "Delivery: #{id}"
              form.action "/raw_materials/deliveries/rmt_deliveries/#{id}/classify_raw_material"
              form.add_field :rmt_code_id if rules[:use_raw_material_code]
              ui_rule.form_object.rmt_classification_types.each do |t|
                form.add_field t.to_sym
              end
            end
          end

          layout
        end
      end
    end
  end
end
