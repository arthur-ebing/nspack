# frozen_string_literal: true

module UiRules
  class DataminerReportRule < Base
    def generate_rules
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      form_name 'report'
    end

    def common_fields
      {
        filename: { renderer: :label },
        caption: { required: true },
        limit: { renderer: :integer },
        offset: { renderer: :integer },
        render_url: {}
      }
    end

    def make_form_object
      details = @options[:details]
      @form_object = OpenStruct.new(
        filename: details.filename,
        caption: details.report.caption,
        limit: details.report.limit,
        offset: details.report.offset,
        render_url: details.report.external_settings[:render_url]
      )
    end
  end
end
