# frozen_string_literal: true

module UiRules
  class EcertTrackingUnitStatusRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::EcertRepo.new
      form_values = @options[:form_values] || {}
      @pallet_number = form_values[:pallet_number]

      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'ecert_tracking_unit_status'
    end

    def common_fields
      left_body = @repo.flatten_hash(@options[:res])
      right_header = { Industry: AppConst::E_CERT_INDUSTRY,
                       BusinessID: AppConst::E_CERT_BUSINESS_ID,
                       AgreementCode: nil }
      right_body = @repo.flatten_hash(right_header.merge(@repo.compile_preverify_pallets(@pallet_number).first))
      right_body = {} if @pallet_number.nil?

      {
        pallet_number: { required: true },
        diff: { left_caption: 'eCert',
                right_caption: 'NSPack',
                left_record: { TrackingUnitID: @pallet_number }.merge(left_body),
                right_record: { TrackingUnitID: @pallet_number }.merge(right_body) }
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
      @form_object = OpenStruct.new(pallet_number: nil,
                                    diff: nil)
    end
  end
end
