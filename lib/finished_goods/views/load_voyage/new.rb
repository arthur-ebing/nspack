# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module LoadVoyage
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load_voyage, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Load Voyage'
              form.action '/finished_goods/dispatch/load_voyages'
              form.remote! if remote
              form.add_field :load_id
              form.add_field :voyage_id
              form.add_field :shipping_line_party_role_id
              form.add_field :shipper_party_role_id
              form.add_field :booking_reference
              form.add_field :memo_pad
            end
          end

          layout
        end
      end
    end
  end
end
