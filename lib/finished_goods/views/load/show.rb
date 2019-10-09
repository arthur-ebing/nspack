# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Load
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Load'
              form.view_only!
              form.add_field :depot_id
              form.add_field :customer_party_role_id
              form.add_field :consignee_party_role_id
              form.add_field :billing_client_party_role_id
              form.add_field :exporter_party_role_id
              form.add_field :final_receiver_party_role_id
              form.add_field :final_destination_id
              form.add_field :pol_voyage_port_id
              form.add_field :pod_voyage_port_id
              form.add_field :order_number
              form.add_field :edi_file_name
              form.add_field :customer_order_number
              form.add_field :customer_reference
              form.add_field :exporter_certificate_code
              form.add_field :shipped_date
              form.add_field :shipped
              form.add_field :transfer_load
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
