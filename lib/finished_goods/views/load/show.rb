# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Load
      class Show # rubocop:disable Metrics/ClassLength
        def self.call(id, user: nil, back_url: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, user.nil? ? :show : :ship, id: id, user: user)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
              section.add_control(control_type: :link,
                                  text: 'Print Dispatch Note',
                                  url: "/finished_goods/reports/dispatch_note/#{id}",
                                  loading_window: true,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Print Dispatch Note - Summarised',
                                  url: "/finished_goods/reports/dispatch_note_summarised/#{id}",
                                  loading_window: true,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Print Dispatch Picklist',
                                  url: "/finished_goods/reports/picklist/#{id}",
                                  loading_window: true,
                                  style: :button)
            end
            page.form do |form| # rubocop:disable Metrics/BlockLength
              form.action '/list/loads'
              form.submit_captions 'Close'
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
                    col.add_field :order_number
                    col.add_field :customer_order_number
                    col.add_field :customer_reference
                    col.add_field :depot_id
                  end
                  row.column do |col|
                    col.add_field :exporter_certificate_code
                    col.add_field :edi_file_name
                    col.add_field :shipped_at
                    col.add_field :shipped
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
                  end
                  row.column do |col|
                    col.add_field :pol_port_id
                    col.add_field :pod_port_id
                    col.add_field :final_destination_id
                    col.add_field :transfer_load
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
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Unship Load',
                                  url: "/finished_goods/dispatch/loads/#{id}/unship",
                                  visible: rules[:can_unship],
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Ship Load',
                                  url: "/finished_goods/dispatch/loads/#{id}/ship",
                                  visible: rules[:can_ship],
                                  style: :button)
              section.add_grid('stock_pallets',
                               "/list/stock_pallets/grid?key=on_load&load_id=#{id}",
                               caption: 'Pallets')
            end
          end

          layout
        end
      end
    end
  end
end
