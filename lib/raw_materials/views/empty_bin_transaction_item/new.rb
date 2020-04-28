# frozen_string_literal: true

module RawMaterials
  module EmptyBins
    module EmptyBinTransactionItem
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true, interactor: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:empty_bin_transaction_item, :new, form_values: form_values, interactor: interactor)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |sec|
              sec.form do |form|
                form.caption 'Add Empty Bin Type'
                form.action '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/add'
                form.remote! if remote
                form.add_field :rmt_container_material_owner_id
                form.add_field :rmt_container_material_type_id
                form.add_field :quantity_bins

                form.submit_captions 'Add', 'Adding'
              end
            end

            page.section do |sec|
              sec.form do |form|
                form.caption 'Remove Empty Bin Type'
                form.action '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/remove'
                form.remote! if remote
                form.add_field :empty_bin_type_ids

                form.submit_captions 'Remove', 'Removing'
              end
            end

            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Done',
                                  url: '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/done',
                                  behaviour: :replace_dialog,
                                  style: :button)
            end
          end

          layout
        end
      end
    end
  end
end
