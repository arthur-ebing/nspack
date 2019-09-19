# frozen_string_literal: true

module UiRules
  class RmtDeliveryRule < Base
    def generate_rules
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      @rules[:show_delivery_destination] = AppConst::DELIVERY_USE_DELIVERY_DESTINATION == 'true'
      @rules[:show_qty_damaged_bins] = AppConst::DELIVERY_CAPTURE_DAMAGED_BINS == 'true'
      @rules[:show_qty_empty_bins] = AppConst::DELIVERY_CAPTURE_EMPTY_BINS == 'true'
      @rules[:show_truck_registration_number] = AppConst::DELIVERY_CAPTURE_TRUCK_AT_FRUIT_RECEPTION == 'true'
      @rules[:scan_rmt_bin_asset_numbers] = AppConst::SCAN_RMT_BIN_ASSET_NUMBERS == 'true'

      set_show_fields if %i[show reopen].include? @mode
      add_behaviours if %i[new edit].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'rmt_delivery'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      orchard_id_label = MasterfilesApp::FarmRepo.new.find_orchard(@form_object.orchard_id)&.orchard_code
      cultivar_id_label = MasterfilesApp::CultivarRepo.new.find_cultivar(@form_object.cultivar_id)&.cultivar_name
      rmt_delivery_destination_id_label = MasterfilesApp::RmtDeliveryDestinationRepo.new.find_rmt_delivery_destination(@form_object.rmt_delivery_destination_id)&.delivery_destination_code
      season_id_label = MasterfilesApp::CalendarRepo.new.find_season(@form_object.season_id)&.season_code
      farm_id_label = MasterfilesApp::FarmRepo.new.find_farm(@form_object.farm_id)&.farm_code
      puc_id_label = MasterfilesApp::FarmRepo.new.find_puc(@form_object.puc_id)&.puc_code
      fields[:orchard_id] = { renderer: :label, with_value: orchard_id_label, caption: 'Orchard' }
      fields[:cultivar_id] = { renderer: :label, with_value: cultivar_id_label, caption: 'Cultivar' }
      fields[:rmt_delivery_destination_id] = { renderer: :label, with_value: rmt_delivery_destination_id_label, caption: 'Rmt Delivery Destination' }
      fields[:season_id] = { renderer: :label, with_value: season_id_label, caption: 'Season' }
      fields[:farm_id] = { renderer: :label, with_value: farm_id_label, caption: 'Farm' }
      fields[:puc_id] = { renderer: :label, with_value: puc_id_label, caption: 'Puc' }
      fields[:truck_registration_number] = { renderer: :label }
      fields[:qty_damaged_bins] = { renderer: :label }
      fields[:qty_empty_bins] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:delivery_tipped] = { renderer: :label, as_boolean: true }
      fields[:date_picked] = { renderer: :label }
      fields[:date_delivered] = { renderer: :label }
      fields[:tipping_complete_date_time] = { renderer: :label }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_RMT_DELIVERY_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields # rubocop:disable Metrics/AbcSize
      fields = {
        farm_id: { renderer: :select, options: MasterfilesApp::FarmRepo.new.for_select_farms, disabled_options: MasterfilesApp::FarmRepo.new.for_select_inactive_farms, caption: 'Farm',
                   required: true, prompt: true },  # ClientSettings.default_farm
        puc_id: { renderer: :select, options: [], caption: 'Puc', required: true, prompt: true },  # ClientSettings.default_puc
        orchard_id: { renderer: :select, options: [], caption: 'Orchard', required: true, prompt: true  },
        cultivar_id: { renderer: :select, options: [], caption: 'Cultivar', required: true, prompt: true },
        rmt_delivery_destination_id: { renderer: :select, options: MasterfilesApp::RmtDeliveryDestinationRepo.new.for_select_rmt_delivery_destinations,
                                       disabled_options: MasterfilesApp::RmtDeliveryDestinationRepo.new.for_select_inactive_rmt_delivery_destinations, caption: 'rmt_delivery_destination',
                                       required: true, prompt: true },
        truck_registration_number: {},
        qty_damaged_bins: {},
        qty_empty_bins: {},
        date_picked: { renderer: :date },
        date_delivered: { renderer: :date }
      }

      fields[:puc_id][:options] = RawMaterialsApp::RmtDeliveryRepo.new.farm_pucs(@form_object.farm_id) unless @form_object.farm_id.nil_or_empty?
      fields[:orchard_id][:options] = RawMaterialsApp::RmtDeliveryRepo.new.orchards(@form_object.farm_id, @form_object.puc_id) unless @form_object.puc_id.nil_or_empty?
      fields[:cultivar_id][:options] = RawMaterialsApp::RmtDeliveryRepo.new.orchard_cultivars(@form_object.orchard_id) unless @form_object.orchard_id.nil_or_empty?
      fields
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_delivery(@options[:id])
    end

    def make_new_form_object
      res = @repo.default_farm_puc
      @form_object = OpenStruct.new(orchard_id: nil,
                                    cultivar_id: nil,
                                    rmt_delivery_destination_id: nil,
                                    season_id: nil,
                                    farm_id: res[:farm_id],
                                    puc_id: res[:puc_id],
                                    truck_registration_number: nil,
                                    qty_damaged_bins: nil,
                                    qty_empty_bins: nil,
                                    delivery_tipped: nil,
                                    date_picked: Time.now,
                                    date_delivered: Time.now,
                                    tipping_complete_date_time: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :farm_id, notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/farm_combo_changed' }]
        behaviour.dropdown_change :puc_id, notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/puc_combo_changed', param_keys: %i[rmt_delivery_farm_id rmt_delivery_puc_id] }]
        behaviour.dropdown_change :orchard_id, notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/orchard_combo_changed', param_keys: %i[rmt_delivery_orchard_id] }]
      end
    end

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
