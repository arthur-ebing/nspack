# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Load
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Load'
              form.action "/finished_goods/dispatch/loads/#{id}"
              form.remote!
              form.method :update
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
            end
          end

          layout
        end
      end
    end
  end
end
