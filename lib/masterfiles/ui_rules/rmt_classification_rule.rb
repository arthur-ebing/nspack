# frozen_string_literal: true

module UiRules
  class RmtClassificationRule < Base
    def generate_rules
      @repo = MasterfilesApp::AdvancedClassificationsRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'rmt_classification'
    end

    def set_show_fields
      # rmt_classification_type_id_label = MasterfilesApp::RmtClassificationTypeRepo.new.find_rmt_classification_type(@form_object.rmt_classification_type_id)&.rmt_classification_type_code
      # rmt_classification_type_id_label = @repo.find(:rmt_classification_types, MasterfilesApp::RmtClassificationType, @form_object.rmt_classification_type_id)&.rmt_classification_type_code
      rmt_classification_type_id_label = @repo.get(:rmt_classification_types, @form_object.rmt_classification_type_id, :rmt_classification_type_code)
      fields[:rmt_classification_type_id] = { renderer: :label, with_value: rmt_classification_type_id_label, caption: 'Rmt Classification Type' }
      fields[:rmt_classification] = { renderer: :label }
    end

    def common_fields
      {
        rmt_classification: { required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_classification(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::RmtClassification)
    end
  end
end
