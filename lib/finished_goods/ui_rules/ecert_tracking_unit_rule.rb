# frozen_string_literal: true

module UiRules
  class EcertTrackingUnitRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::EcertRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'ecert_tracking_unit'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      # pallet_id_label = FinishedGoodsApp::PalletRepo.new.find_pallet(@form_object.pallet_id)&.pallet_number
      pallet_id_label = @repo.find(:pallets, FinishedGoodsApp::Pallet, @form_object.pallet_id)&.pallet_number
      # ecert_agreement_id_label = FinishedGoodsApp::EcertRepo.new.find_ecert_agreement(@form_object.ecert_agreement_id)&.code
      ecert_agreement_id_label = @repo.find(:ecert_agreements, FinishedGoodsApp::EcertAgreement, @form_object.ecert_agreement_id)&.code
      fields[:pallet_id] = { renderer: :label, with_value: pallet_id_label, caption: 'Pallet' }
      fields[:ecert_agreement_id] = { renderer: :label, with_value: ecert_agreement_id_label, caption: 'Ecert Agreement' }
      fields[:business_id] = { renderer: :label }
      fields[:industry] = { renderer: :label }
      fields[:elot_key] = { renderer: :label }
      fields[:verification_key] = { renderer: :label }
      fields[:passed] = { renderer: :label, as_boolean: true }
      fields[:process_result] = { renderer: :label }
      fields[:rejection_reasons] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        ecert_agreement_id: { renderer: :select,
                              options: FinishedGoodsApp::EcertRepo.new.for_select_ecert_agreements,
                              disabled_options: FinishedGoodsApp::EcertRepo.new.for_select_inactive_ecert_agreements,
                              caption: 'eCert Agreement',
                              required: true },
        business_id: { required: true },
        industry: { required: true },
        elot_key: {},
        verification_key: {},
        passed: { renderer: :checkbox },
        process_result: {},
        rejection_reasons: {},
        pallet_list: { renderer: :textarea, rows: 12,
                       placeholder: 'Paste pallet numbers here',
                       caption: 'Pallet Numbers',
                       required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_ecert_tracking_unit(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pallet_id: nil,
                                    ecert_agreement_id: nil,
                                    business_id: nil,
                                    industry: nil,
                                    elot_key: nil,
                                    verification_key: nil,
                                    passed: nil,
                                    process_result: nil,
                                    rejection_reasons: nil,
                                    pallet_list: nil)
    end
  end
end
