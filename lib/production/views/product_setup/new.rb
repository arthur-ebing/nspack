# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetup
      class New
        def self.call(product_setup_template_id, form_values: nil, form_errors: nil, remote: true)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:product_setup, :new, product_setup_template_id: product_setup_template_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form| # rubocop:disable Metrics/BlockLength
              form.caption 'New Product Setup'
              form.action "/production/product_setups/product_setup_templates/#{product_setup_template_id}/product_setups/new"
              form.remote! if remote
              form.add_field :product_setup_template
              form.add_field :product_setup_template_id
              form.expand_collapse button: true, mini: false
              form.fold_up do |fold|
                fold.caption 'Fruit details'
                fold.add_field :commodity_id
                fold.add_field :marketing_variety_id
                fold.add_field :std_fruit_size_count_id
                fold.add_field :basic_pack_code_id
                fold.add_field :fruit_actual_counts_for_pack_id
                fold.add_field :standard_pack_code_id
                fold.add_field :fruit_size_reference_id
                fold.add_field :grade_id
              end
              form.fold_up do |fold|
                fold.caption 'Marketing details'
                fold.add_field :marketing_org_party_role_id
                fold.add_field :packed_tm_group_id
                fold.add_field :sell_by_code
                fold.add_field :mark_id
                fold.add_field :product_chars
                fold.add_field :inventory_code_id
                fold.add_field :customer_variety_variety_id
                fold.add_field :client_product_code
                fold.add_field :client_size_reference
              end
              form.fold_up do |fold|
                fold.caption 'Packaging details'
                fold.add_field :pallet_base_id
                fold.add_field :pallet_stack_type_id
                fold.add_field :pallet_format_id
                fold.add_field :pallet_label_name
                fold.add_field :cartons_per_pallet_id
                fold.add_field :pm_type_id
                fold.add_field :pm_subtype_id
                fold.add_field :pm_bom_id
                fold.add_field :description
                fold.add_field :erp_bom_code
                fold.add_field :pm_boms_products
              end
              # form.fold_up do |fold|
              #   fold.caption 'Custom fields'
              #   fold.add_field :extended_columns
              # end
              form.fold_up do |fold|
                fold.caption 'Treatment Details'
                fold.add_field :treatment_type_id
                fold.add_field :treatment_ids
              end
            end
          end

          layout
        end
      end
    end
  end
end
