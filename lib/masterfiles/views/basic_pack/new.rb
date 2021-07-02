# frozen_string_literal: true

module Masterfiles
  module Fruit
    module BasicPack
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:basic_pack, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/masterfiles/fruit/basic_pack_codes'
              form.remote! if remote
              form.add_field :basic_pack_code
              form.add_field :description
              form.add_field :length_mm
              form.add_field :width_mm
              form.add_field :height_mm
              form.add_field :footprint_code
              form.add_field :bin
              form.add_field :standard_pack_ids
            end
          end

          layout
        end
      end
    end
  end
end
