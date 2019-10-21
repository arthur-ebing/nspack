# frozen_string_literal: true

module UiRules
  class LoadVoyageRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::LoadVoyageRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'load_voyage'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      load_id_label = FinishedGoodsApp::LoadRepo.new.find_load(@form_object.load_id)&.order_number
      voyage_id_label = FinishedGoodsApp::VoyageRepo.new.find_voyage(@form_object.voyage_id)&.voyage_number
      shipping_line_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.shipping_line_party_role_id)&.id
      shipper_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.shipper_party_role_id)&.id
      fields[:load_id] = { renderer: :label, with_value: load_id_label, caption: 'Load' }
      fields[:voyage_id] = { renderer: :label, with_value: voyage_id_label, caption: 'Voyage' }
      fields[:shipping_line_party_role_id] = { renderer: :label, with_value: shipping_line_party_role_id_label, caption: 'Shipping Line' }
      fields[:shipper_party_role_id] = { renderer: :label, with_value: shipper_party_role_id_label, caption: 'Shipper' }
      fields[:booking_reference] = { renderer: :label }
      fields[:memo_pad] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        load_id: { renderer: :select, options: FinishedGoodsApp::LoadRepo.new.for_select_loads, caption: 'Load', required: true },
        voyage_id: { renderer: :select, options: FinishedGoodsApp::VoyageRepo.new.for_select_voyages, caption: 'Voyage', required: true },
        shipping_line_party_role_id: { renderer: :select, options: MasterfilesApp::PartyRepo.new.for_select_party_roles, caption: 'Shipping Line', required: true },
        shipper_party_role_id: { renderer: :select, options: MasterfilesApp::PartyRepo.new.for_select_party_roles, caption: 'Shipper', required: true },
        booking_reference: { required: true },
        memo_pad: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_load_voyage(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(load_id: nil,
                                    voyage_id: nil,
                                    shipping_line_party_role_id: nil,
                                    shipper_party_role_id: nil,
                                    booking_reference: nil,
                                    memo_pad: nil)
    end
  end
end
