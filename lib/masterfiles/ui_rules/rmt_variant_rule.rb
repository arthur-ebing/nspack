# frozen_string_literal: true

module UiRules
  class RmtVariantRule < Base
    def generate_rules
      @repo = MasterfilesApp::AdvancedClassificationsRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'rmt_variant'
    end

    def set_show_fields
      # cultivar_id_label = MasterfilesApp::CultivarRepo.new.find_cultivar(@form_object.cultivar_id)&.cultivar_name
      # cultivar_id_label = @repo.find(:cultivars, MasterfilesApp::Cultivar, @form_object.cultivar_id)&.cultivar_name
      cultivar_id_label = @repo.get(:cultivars, @form_object.cultivar_id, :cultivar_name)
      fields[:cultivar_id] = { renderer: :label, with_value: cultivar_id_label, caption: 'Cultivar' }
      fields[:rmt_variant_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    def common_fields
      {
        cultivar_id: { renderer: :select, options: MasterfilesApp::CultivarRepo.new.for_select_cultivars,
                       disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivars,
                       caption: 'Cultivar', required: true },
        rmt_variant_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_variant(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::RmtVariant)
    end
  end
end
