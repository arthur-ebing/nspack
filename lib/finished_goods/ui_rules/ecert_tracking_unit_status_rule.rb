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

      form_name 'ecert_tracking_unit_status'
    end

    def common_fields
      left_body = @repo.flatten_hash(@options[:res])
      right_body = @repo.flatten_hash(@repo.compile_preverify_pallets(@pallet_number).first)

      header = {}
      %i[TrackingUnitID AgreementCode BusinessID ExportProcess Industry ProcessResult ProcessStatus RejectionReasons UpdatedDateTime ExportDate].each do |k|
        header[k] = left_body.delete(k)
        right_body.delete(k)
      end
      {
        pallet_number: { required: true },
        header: { left_caption: '',
                  right_caption: '',
                  left_record: header,
                  right_record: {} },
        diff: { left_caption: 'eCert',
                right_caption: 'NSPack',
                left_record: left_body,
                right_record: right_body }
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
