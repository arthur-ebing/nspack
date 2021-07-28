# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module PalletHoldover
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:pallet_holdover, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Pallet Holdover'
              form.action "/finished_goods/dispatch/pallet_holdovers/#{id}"
              form.remote!
              form.method :update
              form.add_field :pallet_id
              form.add_field :holdover_quantity
              form.add_field :buildup_remarks
              form.add_field :completed
            end
          end
        end
      end
    end
  end
end
