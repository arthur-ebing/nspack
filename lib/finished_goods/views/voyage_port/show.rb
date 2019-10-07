# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module VoyagePort
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:voyage_port, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Voyage Port'
              form.view_only!
              form.add_field :port_type_id
              form.add_field :port_id
              form.add_field :trans_shipment_vessel_id
              form.add_field :ata
              form.add_field :atd
              form.add_field :eta
              form.add_field :etd
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
