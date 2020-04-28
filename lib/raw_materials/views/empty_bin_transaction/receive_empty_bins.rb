# frozen_string_literal: true

module RawMaterials
  module EmptyBins
    module EmptyBinTransaction
      class ReceiveEmptyBins
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:empty_bin_transaction, :receive, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Receive Empty Bins'
              form.action '/raw_materials/empty_bins/empty_bin_transactions/receive_empty_bins'
              form.remote! if remote

              form.add_field :business_process_id
              form.add_field :reference_number
              form.add_field :asset_transaction_type_id
              form.add_field :empty_bin_from_location_id
              form.add_field :empty_bin_to_location_id
              form.add_field :fruit_reception_delivery_id
              form.add_field :truck_registration_number
              form.add_field :quantity_bins

              form.submit_captions 'Next'
            end
          end

          layout
        end
      end
    end
  end
end
