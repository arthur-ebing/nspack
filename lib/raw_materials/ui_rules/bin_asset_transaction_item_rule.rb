# frozen_string_literal: true

module UiRules
  class BinAssetTransactionItemRule < Base
    def generate_rules
      @repo = RawMaterialsApp::BinAssetsRepo.new
      make_form_object
      apply_form_values
      add_behaviours
      common_values_for_fields common_fields
      make_header
      form_name 'bin_asset_transaction_item'
    end

    def common_fields
      {
        rmt_material_owner_party_role_id: { renderer: :select,
                                            options: @repo.for_select_bin_asset_owners,
                                            min_charwidth: 30,
                                            caption: 'Owner',
                                            prompt: true,
                                            required: true },
        rmt_container_material_type_id: { renderer: :select,
                                          options: [],
                                          required: true,
                                          caption: 'Type' },
        quantity_bins: { renderer: :integer, required: true },
        bin_sets: { renderer: :list, items: bin_sets, remove_item_url: '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/remove/$:id$' }
      }
    end

    def make_form_object
      @form_object = OpenStruct.new(header_info.merge(rmt_material_owner_party_role_id: nil,
                                                      rmt_container_material_type_id: nil,
                                                      quantity_bins: nil))
    end

    def onsite_empty_bin_asset_location_id
      @repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_EMPTY_BIN_LOCATION)
    end

    def make_header
      columns = header_info.keys
      compact_header(columns: columns,
                     display_columns: 2,
                     header_captions: { bin_asset_from_location_id: 'From Location', bin_asset_to_location_id: 'To Location' })
    end

    private

    def header_info
      @repo.resolve_for_header(@options[:interactor]&.stepper&.read)
    end

    def add_behaviours
      behaviours do |behaviour|
        owner_changed_url = '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/owner_changed'
        behaviour.dropdown_change :rmt_material_owner_party_role_id, notify: [{ url: owner_changed_url }]
      end
    end

    def bin_sets
      @options[:interactor]&.stepper&.for_select_bin_sets || []
    end
  end
end
