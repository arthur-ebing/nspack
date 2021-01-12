# frozen_string_literal: true

module UiRules
  class PmMarkRule < Base
    def generate_rules
      @repo = MasterfilesApp::BomRepo.new
      make_form_object
      apply_form_values

      @rules[:composition_levels] = composition_levels
      @rules[:items] = @form_object.packaging_marks.nil_or_empty? ? [] : @form_object.packaging_marks

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'pm_mark'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      mark_id_label = @repo.find(:marks, MasterfilesApp::Mark, @form_object.mark_id)&.mark_code
      fields[:mark_id] = { renderer: :label,
                           with_value: mark_id_label,
                           caption: 'Fruitspec Mark' }
      fields[:description] = { renderer: :label }
      rules[:composition_levels].each do |key, val|
        fields[key.to_s.to_sym] = { renderer: :label,
                                    caption: "#{val} Mark",
                                    with_value: rules[:items][key - 1].to_s }
      end
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      fields = {
        mark_id: { renderer: :select,
                   options: MasterfilesApp::MarketingRepo.new.for_select_marks,
                   disabled_options: MasterfilesApp::MarketingRepo.new.for_select_inactive_marks,
                   caption: 'Fruitspec Mark',
                   required: true },
        description: { required: true }
      }
      rules[:composition_levels].each do |key, val|
        fields[key.to_s.to_sym] = { force_uppercase: true,
                                    caption: "#{val} Mark",
                                    value: rules[:items][key - 1].to_s }
      end
      fields
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      res = @repo.find_pm_mark(@options[:id])
      items = @repo.array_of_text_for_db_col(res.packaging_marks)
      extra = {}
      composition_levels.each do |key, _val|
        extra[key.to_s] = items[key - 1].to_s
      end
      @form_object = OpenStruct.new(res.to_h.merge(extra))
    end

    def make_new_form_object
      @form_object = OpenStruct.new(mark_id: nil,
                                    packaging_marks: nil,
                                    description: nil)
    end

    def composition_levels
      @repo.pm_composition_levels
    end
  end
end
