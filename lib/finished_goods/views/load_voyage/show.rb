# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module LoadVoyage
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:load_voyage, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Load Voyage'
              form.view_only!
              form.add_field :load_id
              form.add_field :voyage_id
              form.add_field :shipping_line_party_role_id
              form.add_field :shipper_party_role_id
              form.add_field :booking_reference
              form.add_field :memo_pad
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
