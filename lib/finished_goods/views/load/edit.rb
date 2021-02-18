# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Dispatch
    module Load
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: "/finished_goods/dispatch/loads/#{id}",
                                  style: :back_button)
            end
            page.form do |form|
              form.action "/finished_goods/dispatch/loads/#{id}"
              form.method :update
              form.fold_up do |fold|
                fold.caption 'Parties'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :customer_party_role_id
                    col.add_field :consignee_party_role_id
                    col.add_field :final_receiver_party_role_id
                  end
                  row.column do |col|
                    col.add_field :exporter_party_role_id
                    col.add_field :billing_client_party_role_id
                  end
                end
              end
              form.fold_up do |fold|
                fold.caption 'Load Details'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :id
                    col.add_field :load_id
                    col.add_field :order_number
                    col.add_field :customer_order_number
                    col.add_field :customer_reference
                    col.add_field :depot_id
                    col.add_field :location_of_issue
                  end
                  row.column do |col|
                    col.add_field :status
                    col.add_field :exporter_certificate_code
                    col.add_field :edi_file_name
                    col.add_field :shipped_at
                    col.add_field :requires_temp_tail
                  end
                end
              end
              form.fold_up do |fold|
                fold.caption 'Voyage Ports and Locations'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :voyage_type_id
                    col.add_field :vessel_id
                    col.add_field :voyage_number
                    col.add_field :year
                    col.add_field :final_destination_id
                    col.add_field :transfer_load
                  end
                  row.column do |col|
                    col.add_field :pol_port_id
                    col.add_field :pod_port_id
                  end
                end
              end
              form.fold_up do |fold|
                fold.caption 'Load Voyage'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :shipping_line_party_role_id
                    col.add_field :shipper_party_role_id
                    col.add_field :booking_reference
                  end
                  row.column do |col|
                    col.add_field :memo_pad
                  end
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
