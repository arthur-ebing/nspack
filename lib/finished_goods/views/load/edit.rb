# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Dispatch
    module Load
      class Edit
        def self.call(id, back_url: nil, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Load'
              form.action "/finished_goods/dispatch/loads/#{id}"
              form.remote!
              page.section do |section|
                section.add_control(control_type: :link,
                                    text: 'Back',
                                    url: back_url,
                                    style: :back_button)
              end
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :transfer_load
                  col.add_field :customer_party_role_id
                  col.add_field :consignee_party_role_id
                  col.add_field :final_receiver_party_role_id
                  col.add_field :exporter_party_role_id
                  col.add_field :billing_client_party_role_id
                  col.add_field :depot_id
                  col.add_field :final_destination_id
                end
                row.column do |col|
                  col.add_field :pol_voyage_port_id
                  col.add_field :pod_voyage_port_id
                  col.add_field :order_number
                  col.add_field :edi_file_name
                  col.add_field :customer_order_number
                  col.add_field :customer_reference
                  col.add_field :exporter_certificate_code
                  col.add_field :shipped_date
                  col.add_field :shipped
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
