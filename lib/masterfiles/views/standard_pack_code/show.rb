# frozen_string_literal: true

module Masterfiles
  module Fruit
    module StandardPackCode
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:standard_pack_code, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.add_field :basic_pack_code_id
              form.add_field :standard_pack_code
              form.add_field :description
              form.add_field :std_pack_label_code
              form.add_field :material_mass
              form.add_field :plant_resource_button_indicator
              form.add_field :use_size_ref_for_edi
              form.add_field :palletizer_incentive_rate
              form.add_field :bin
              form.add_field :rmt_container_type_id
              form.add_field :rmt_container_material_type_id
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
