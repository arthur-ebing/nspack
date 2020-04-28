# frozen_string_literal: true

module UiRules
  class EmptyBinTransactionRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = RawMaterialsApp::EmptyBinsRepo.new
      make_form_object
      apply_form_values
      add_behaviours

      common_values_for_fields case @mode
                               when :receive
                                 receive_empty_bins_fields
                               when :issue
                                 issue_empty_bins_fields
                               when :adhoc
                                 adhoc_transaction_fields
                               else
                                 show_fields
                               end
      # set_show_fields if @mode == :show

      form_name 'empty_bin_transaction'
    end

    # def set_show_fields
    #   # asset_transaction_type_id_label = RawMaterialsApp::AssetTransactionTypeRepo.new.find_asset_transaction_type(@form_object.asset_transaction_type_id)&.transaction_type_code
    #   asset_transaction_type_id_label = @repo.find(:asset_transaction_types, RawMaterialsApp::AssetTransactionType, @form_object.asset_transaction_type_id)&.transaction_type_code
    #   # empty_bin_to_location_id_label = RawMaterialsApp::LocationRepo.new.find_location(@form_object.empty_bin_to_location_id)&.location_long_code
    #   empty_bin_to_location_id_label = @repo.find(:locations, RawMaterialsApp::Location, @form_object.empty_bin_to_location_id)&.location_long_code
    #   # fruit_reception_delivery_id_label = RawMaterialsApp::RmtDeliveryRepo.new.find_rmt_delivery(@form_object.fruit_reception_delivery_id)&.truck_registration_number
    #   fruit_reception_delivery_id_label = @repo.find(:rmt_deliveries, RawMaterialsApp::RmtDelivery, @form_object.fruit_reception_delivery_id)&.truck_registration_number
    #   # business_process_id_label = RawMaterialsApp::BusinessProcessRepo.new.find_business_process(@form_object.business_process_id)&.process
    #   business_process_id_label = @repo.find(:business_processes, RawMaterialsApp::BusinessProcess, @form_object.business_process_id)&.process
    #   fields[:asset_transaction_type_id] = { renderer: :label, with_value: asset_transaction_type_id_label, caption: 'Asset Transaction Type' }
    #   fields[:empty_bin_to_location_id] = { renderer: :label, with_value: empty_bin_to_location_id_label, caption: 'Empty Bin To Location' }
    #   fields[:fruit_reception_delivery_id] = { renderer: :label, with_value: fruit_reception_delivery_id_label, caption: 'Fruit Reception Delivery' }
    #   fields[:business_process_id] = { renderer: :label, with_value: business_process_id_label, caption: 'Business Process' }
    #   fields[:quantity_bins] = { renderer: :label }
    #   fields[:truck_registration_number] = { renderer: :label }
    #   fields[:reference_number] = { renderer: :label }
    #   fields[:created_by] = { renderer: :label }
    #   fields[:is_adhoc] = { renderer: :label, as_boolean: true }
    # end

    def show_fields
      {
        asset_transaction_type_id: { renderer: :label, value: @form_object.transaction_type_code, caption: 'Transaction Type Code' },
        quantity_bins: { renderer: :label, caption: 'Total Qty Empty Bins' },
        reference_number: { renderer: :label },
        business_process_id: { renderer: :label, value: @form_object.process, caption: 'Business Process' },
        fruit_reception_delivery_id: { renderer: :label, value: @form_object.fruit_reception_delivery_id, caption: 'Delivery' },
        empty_bin_to_location_id: { renderer: :label, value: @form_object.location_long_code, caption: 'To Location' },
        created_by: { renderer: :label },
        truck_registration_number: { renderer: :label },
        is_adhoc: { renderer: :label }
      }
    end

    def adhoc_transaction_fields
      fields = {
        business_process_id: { renderer: :hidden },
        empty_bin_from_location_id: { renderer: :select,
                                      options: @repo.for_select_available_empty_bin_locations,
                                      caption: 'From Location',
                                      required: true },
        empty_bin_to_location_id: { renderer: :select,
                                    options: @repo.for_select_empty_bin_locations,
                                    selected: onsite_empty_bin_location_id,
                                    caption: 'To Location',
                                    required: true },
        is_adhoc: { renderer: :hidden, value: true }
      }
      common_fields.merge(fields)
    end

    def receive_empty_bins_fields
      fields = {
        business_process_id: { renderer: :hidden, value: receive_process_id },
        empty_bin_from_location_id: { renderer: :select,
                                      options: @repo.for_select_available_empty_bin_locations,
                                      caption: 'From Location',
                                      required: true },
        empty_bin_to_location_id: { renderer: :select,
                                    options: @repo.for_select_empty_bin_locations,
                                    selected: onsite_empty_bin_location_id,
                                    caption: 'To Location',
                                    required: true },
        fruit_reception_delivery_id: { renderer: :select,
                                       prompt: true,
                                       options: RawMaterialsApp::RmtDeliveryRepo.new.for_select_rmt_deliveries,
                                       caption: 'Fruit Reception Delivery' },
        truck_registration_number: {}
      }
      common_fields.merge(fields)
    end

    def issue_empty_bins_fields
      fields = {
        business_process_id: { renderer: :hidden, value: issue_process_id },
        empty_bin_from_location_id: { renderer: :hidden, value: onsite_empty_bin_location_id },
        empty_bin_to_location_id: { renderer: :select,
                                    options: @repo.for_select_empty_bin_locations.reject { |r| r[1] == onsite_empty_bin_location_id },
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
        reference_number: { required: true }
      }
    end

    def make_form_object
      @form_object = if %i[issue receive].include?(@mode)
                       make_new_form_object
                     elsif @mode == :adhoc
                       make_adhoc_form_object
                     else
                       @repo.find_empty_bin_transaction(@options[:id])
                     end
    end

    def make_new_form_object
      @form_object = OpenStruct.new(rmt_container_material_owner: nil,
                                    empty_bin_from_location_id: (@mode == :issue ? onsite_empty_bin_location_id : nil),
                                    empty_bin_to_location_id: nil,
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
                                    empty_bin_from_location_id: nil,
                                    empty_bin_to_location_id: nil,
                                    asset_transaction_type_id: asset_transaction_type,
                                    business_process_id: adhoc_process_id,
                                    quantity_bins: nil,
                                    reference_number: nil,
                                    is_adhoc: true)
    end

    private

    def asset_transaction_type
      return @repo.asset_transaction_type_id_for_mode(@mode) if %i[adhoc issue receive].include?(@mode)

      @form_object.asset_transaction_type_id
    end

    def onsite_empty_bin_location_id
      @repo.onsite_empty_bin_location_id
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
        behaviour.dropdown_change :fruit_reception_delivery_id, notify: [{ url: '/raw_materials/empty_bins/empty_bin_transactions/delivery_id_changed' }]
      end
    end
  end
end
