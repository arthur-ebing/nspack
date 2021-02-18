# frozen_string_literal: true

module UiRules
  class TitanRequestRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::TitanRepo.new
      make_form_object
      apply_form_values

      set_show_fields

      form_name 'titan_request'
    end

    def set_show_fields
      fields[:load_id] = { renderer: :label, caption: 'Load',
                           hide_on_load: @form_object.load_id.nil? }
      fields[:govt_inspection_sheet_id] = { renderer: :label, caption: 'Govt Inspection Sheet',
                                            hide_on_load: @form_object.govt_inspection_sheet_id.nil? }
      fields[:request_type] = { renderer: :label }
      fields[:created_at] = { renderer: :label, caption: 'Requested at' }
    end

    def make_form_object
      @form_object = @repo.find_titan_request(@options[:id])
    end
  end
end
