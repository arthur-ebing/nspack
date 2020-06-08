# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Load
      class TempTail
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:load, :temp_tail, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/finished_goods/dispatch/loads/#{id}/temp_tail"
              form.submit_captions 'Add Temp Tail'
              form.method :update
              form.add_field :load_id
              form.add_field :temp_tail_pallet_number
              form.add_field :temp_tail
            end
          end

          layout
        end
      end
    end
  end
end
