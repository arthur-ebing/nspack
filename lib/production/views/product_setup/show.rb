# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetup
      class Show
        def self.call(id)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:product_setup, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Product Setup'
              form.view_only!
              form.add_field :product_setup_template_id
              form.add_field :marketing_variety_id
              form.add_field :customer_variety_variety_id
              form.add_field :std_fruit_size_count_id
              form.add_field :basic_pack_code_id
              form.add_field :standard_pack_code_id
              form.add_field :fruit_actual_counts_for_pack_id
              form.add_field :fruit_size_reference_id
              form.add_field :marketing_org_party_role_id
              form.add_field :packed_tm_group_id
              form.add_field :mark_id
              form.add_field :inventory_code_id
              form.add_field :pallet_format_id
              form.add_field :cartons_per_pallet_id
              form.add_field :pm_bom_id
              # form.add_field :extended_columns
              form.add_field :client_size_reference
              form.add_field :client_product_code
              form.add_field :treatment_ids
              form.add_field :marketing_order_number
              form.add_field :sell_by_code
              form.add_field :pallet_label_name
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
