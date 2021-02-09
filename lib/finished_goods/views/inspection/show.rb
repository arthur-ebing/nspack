# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module Inspection
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:inspection, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Inspection'
              form.view_only!
              form.add_field :inspection_type_code
              form.add_field :pallet_number
              form.add_field :inspector
              form.add_field :failure_reasons
              form.add_field :passed
              form.add_field :remarks
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
