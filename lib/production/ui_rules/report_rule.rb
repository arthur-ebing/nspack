# frozen_string_literal: true

module UiRules
  class PackoutReportRule < Base
    def generate_rules
      make_new_form_object
      common_values_for_fields common_fields

      form_name 'packout_report'
    end

    def common_fields
      {
        from_date: { renderer: :date,
                     required: true,
                     width: 1 },
        to_date: { renderer: :date,
                   required: true },
        detail_level: { renderer: :checkbox,
                        caption: 'Show detail' },
        spacer: { renderer: :hidden }
      }
    end

    def make_new_form_object
      @form_object = OpenStruct.new(from_date: nil,
                                    to_date: nil,
                                    detail_level: true)
    end
  end
end
