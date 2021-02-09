# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module Inspection
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:inspection, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Inspection'
              form.action '/finished_goods/inspection/inspections'
              form.remote! if remote
              form.add_field :pallet_number
            end
          end

          layout
        end
      end
    end
  end
end
