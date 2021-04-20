# frozen_string_literal: true

module RawMaterials
  module BinAssets
    module BinAssetTransaction
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_asset_transaction, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.form do |form|
                form.view_only!
                form.no_submit!
                form.row do |row|
                  row.column do |col|
                    col.add_field :asset_transaction_type_id
                    col.add_field :bin_asset_to_location_id
                    col.add_field :fruit_reception_delivery_id
                    col.add_field :business_process_id
                    col.add_field :quantity_bins
                  end
                  row.column do |col|
                    col.add_field :truck_registration_number
                    col.add_field :reference_number
                    col.add_field :created_by
                    col.add_field :is_adhoc
                  end
                end
              end
            end

            page.section do |section|
              section.add_grid('transaction_items', "/list/transaction_history_items/grid?key=standard&bin_asset_transaction_id=#{id}", caption: 'Transaction Items')
            end
          end

          layout
        end
      end
    end
  end
end
