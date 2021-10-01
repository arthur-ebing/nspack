# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Load
      class EditShippedDate
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:load, :force_shipped_date, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.action "/finished_goods/dispatch/loads/#{id}/force_shipped_date"
              form.remote!
              form.add_field :shipped_at
            end
          end

          layout
        end
      end
    end
  end
end
