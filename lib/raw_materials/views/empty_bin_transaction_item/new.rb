# frozen_string_literal: true

module RawMaterials
  module EmptyBins
    module EmptyBinTransactionItem
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true, interactor: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:empty_bin_transaction_item, :new, form_values: form_values, interactor: interactor)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.section do |sec|
              sec.form do |form|
                form.form_id 'empty_bin_transaction_item'
                form.caption 'Add Empty Bin Type'
                form.action '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/add'
                form.remote! if remote
                form.add_field :rmt_material_owner_party_role_id
                form.add_field :rmt_container_material_type_id
                form.add_field :quantity_bins
                form.add_list ui_rule.form_object.bin_sets, caption: 'Bin Sets List', dom_id: 'bin_set_list'

                form.submit_captions 'Add Bin Set', 'Adding'
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
