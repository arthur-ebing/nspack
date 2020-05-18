# frozen_string_literal: true

module RawMaterials
  module EmptyBins
    module EmptyBinTransaction
      class AdhocDestroy
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:empty_bin_transaction, :adhoc, form_values: form_values, adhoc_type: 'destroy')
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Adhoc Destroy Empty Bins'
              form.action '/raw_materials/empty_bins/empty_bin_transactions/adhoc_destroy'
              form.remote! if remote
              form.add_field :asset_transaction_type_id
              form.add_field :empty_bin_from_location_id
              form.add_field :business_process_id
              form.add_field :quantity_bins
              form.add_field :reference_number
              form.add_field :is_adhoc
              form.add_field :destroy
            end
          end

          layout
        end
      end
    end
  end
end
