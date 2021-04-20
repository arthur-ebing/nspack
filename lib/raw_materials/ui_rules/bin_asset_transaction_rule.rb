# frozen_string_literal: true

module UiRules
  class BinAssetTransactionRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = RawMaterialsApp::BinAssetsRepo.new
      make_form_object
      apply_form_values
      add_behaviours

      common_values_for_fields case @mode
                               when :receive
                                 receive_bin_assets_fields
                               when :issue
                                 issue_bin_assets_fields
                               when :adhoc
                                 adhoc_transaction_fields
                               else
                                 common_fields
                               end
      set_show_fields if @mode == :show
      form_name 'bin_asset_transaction'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:asset_transaction_type_id] = { renderer: :label, with_value: @form_object.transaction_type_code, caption: 'Transaction Type Code' }
      fields[:quantity_bins] = { renderer: :label, caption: 'Total Qty Empty Bins' }
      fields[:reference_number] = { renderer: :label }
      fields[:business_process_id] = { renderer: :label, with_value: @form_object.process, caption: 'Business Process' }
      fields[:fruit_reception_delivery_id] = { renderer: :label, with_value: @form_object.fruit_reception_delivery_id, caption: 'Delivery' }
      fields[:bin_asset_to_location_id] = { renderer: :label, with_value: @form_object.location_long_code, caption: 'To Location' }
      fields[:created_by] = { renderer: :label }
      fields[:truck_registration_number] = { renderer: :label }
      fields[:is_adhoc] = { renderer: :label }
    end

    def adhoc_transaction_fields
      fields = {
        business_process_id: { renderer: :hidden },
        bin_asset_from_location_id: { renderer: :select,
                                      options: @repo.for_select_available_bin_asset_locations,
                                      caption: 'From Location',
                                      required: true },
        bin_asset_to_location_id: { renderer: :select,
                                    options: @repo.for_select_bin_asset_locations,
                                    selected: onsite_bin_asset_location_id,
                                    caption: 'To Location',
                                    required: true },
        create: { renderer: :hidden, value: true },
        destroy: { renderer: :hidden, value: true },
        is_adhoc: { renderer: :hidden, value: true }
      }
      common_fields.merge(fields)
    end

    def receive_bin_assets_fields
      fields = {
        business_process_id: { renderer: :hidden, value: receive_process_id },
        bin_asset_from_location_id: { renderer: :select,
                                      options: @repo.for_select_available_bin_asset_locations,
                                      caption: 'From Location',
                                      required: true },
        bin_asset_to_location_id: { renderer: :select,
                                    options: @repo.for_select_bin_asset_locations,
                                    selected: onsite_bin_asset_location_id,
                                    caption: 'To Location',
                                    required: true },
        fruit_reception_delivery_id: { renderer: :select,
                                       prompt: true,
                                       options: delivery_options,
                                       caption: 'Fruit Reception Delivery' },
        truck_registration_number: {}
      }
      common_fields.merge(fields)
    end

    def issue_bin_assets_fields
      fields = {
        business_process_id: { renderer: :hidden, value: issue_process_id },
        bin_asset_from_location_id: { renderer: :hidden, value: onsite_bin_asset_location_id },
        bin_asset_to_location_id: { renderer: :select,
                                    options: @repo.for_select_bin_asset_locations.reject { |r| r[1] == onsite_bin_asset_location_id },
                                    caption: 'To Location',
                                    required: true },
        truck_registration_number: {}
      }
      common_fields.merge(fields)
    end

    def common_fields
      {
        asset_transaction_type_id: { renderer: :hidden, value: asset_transaction_type },
        quantity_bins: { renderer: :integer, required: true, caption: 'Total Qty Empty Bins' },
        reference_number: {}
      }
    end

    def make_form_object
      @form_object = if %i[issue receive].include?(@mode)
                       make_new_form_object
                     elsif @mode == :adhoc
                       make_adhoc_form_object
                     else
                       @repo.find_bin_asset_transaction(@options[:id])
                     end
    end

    def make_new_form_object
      @form_object = OpenStruct.new(rmt_container_material_owner: nil,
                                    bin_asset_from_location_id: (@mode == :issue ? onsite_bin_asset_location_id : nil),
                                    bin_asset_to_location_id: nil,
                                    asset_transaction_type_id: asset_transaction_type,
                                    fruit_reception_delivery_id: nil,
                                    business_process_id: (@mode == :receive ? receive_process_id : issue_process_id),
                                    quantity_bins: nil,
                                    truck_registration_number: nil,
                                    reference_number: nil,
                                    is_adhoc: nil)
    end

    def make_adhoc_form_object
      @form_object = OpenStruct.new(rmt_container_material_owner: nil,
                                    bin_asset_from_location_id: nil,
                                    bin_asset_to_location_id: nil,
                                    asset_transaction_type_id: asset_transaction_type,
                                    business_process_id: adhoc_process_id,
                                    quantity_bins: nil,
                                    reference_number: nil,
                                    is_adhoc: true,
                                    create: true,
                                    destroy: true)
    end

    private

    def asset_transaction_type
      if %i[issue receive].include?(@mode)
        @repo.asset_transaction_type_id_for_mode(@mode)
      elsif @mode == :adhoc
        @repo.asset_transaction_type_id_for_mode("#{@mode}_#{@options[:adhoc_type]}".to_sym)
      else
        @form_object.asset_transaction_type_id
      end
    end

    def onsite_bin_asset_location_id
      @repo.onsite_bin_asset_location_id
    end

    def receive_process_id
      @repo.get_id(:business_processes, process: AppConst::PROCESS_RECEIVE_EMPTY_BINS)
    end

    def issue_process_id
      @repo.get_id(:business_processes, process: AppConst::PROCESS_ISSUE_EMPTY_BINS)
    end

    def adhoc_process_id
      @repo.get_id(:business_processes, process: AppConst::PROCESS_ADHOC_TRANSACTIONS)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :fruit_reception_delivery_id, notify: [{ url: '/raw_materials/bin_assets/bin_asset_transactions/delivery_id_changed' }]
      end
    end

    def delivery_options
      @repo.for_select_rmt_deliveries
    end
  end
end
