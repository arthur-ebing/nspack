# frozen_string_literal: true

module UiRules
  class EdiViewerRule < Base
    def generate_rules
      # @repo = EdiApp::ViewerRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      form_name 'edi_file_upload'
    end

    def common_fields
      {
        flow_type: { renderer: :select, options: %w[PO PS], required: true },
        file_name: { renderer: :file, required: true }
      }
    end

    def make_form_object
      @form_object = OpenStruct.new(flow_type: nil,
                                    file_name: nil)
    end
  end
end
