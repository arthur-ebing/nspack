# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Load
      class New
        def self.call(back_url, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              # form.caption 'New Load'
              form.action '/finished_goods/dispatch/loads'
              form.remote! if remote
              page.section do |section|
                section.add_control(control_type: :link,
                                    text: 'Back',
                                    url: back_url,
                                    style: :back_button)
              end

              form.add_field :customer_party_role_id
              form.add_field :consignee_party_role_id
              form.add_field :billing_client_party_role_id
              form.add_field :exporter_party_role_id
              form.add_field :final_receiver_party_role_id
              form.add_field :depot_id
              form.add_field :final_destination_id
            end
            page.form do |form|
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
