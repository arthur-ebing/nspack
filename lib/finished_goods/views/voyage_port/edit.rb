# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module VoyagePort
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:voyage_port, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Voyage Port'
              form.action "/finished_goods/dispatch/voyage_ports/#{id}"
              form.remote!
              form.method :update
              form.add_field :voyage_id
              form.add_field :port_type_id
              form.add_field :port_id
              form.add_field :eta
              form.add_field :ata
              form.add_field :etd
              form.add_field :atd
              form.add_field :trans_shipment_vessel_id
            end
          end

          layout
        end
      end
    end
  end
end
