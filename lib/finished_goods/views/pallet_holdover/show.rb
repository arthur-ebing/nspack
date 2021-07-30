# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module PalletHoldover
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:pallet_holdover, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Pallet Holdover'
              form.view_only!
              form.add_field :pallet_id
              form.add_field :holdover_quantity
              form.add_field :buildup_remarks
            end
          end
        end
      end
    end
  end
end
