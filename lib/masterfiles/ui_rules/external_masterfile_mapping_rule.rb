# frozen_string_literal: true

module UiRules
  class ExternalMasterfileMappingRule < Base
    def generate_rules
      @repo = MasterfilesApp::GeneralRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields if %i[new edit].include? @mode

      add_behaviours if %i[new].include? @mode

      set_show_fields if %i[show].include? @mode

      form_name 'external_masterfile_mapping'
    end

    def set_show_fields
      fields[:external_system] = { renderer: :label,
                                   with_value: @form_object.external_system,
                                   caption: 'External System' }
      fields[:masterfile_table] = { renderer: :label,
                                    with_value: @form_object.mapping,
                                    caption: 'Mapping' }
      fields[:external_code] = { renderer: :label,
                                 caption: 'Mapping Code' }
      fields[:masterfile_id] = { renderer: :label }
      fields[:masterfile_code] = { renderer: :label,
                                   with_value: @form_object.masterfile_code }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      if @form_object.masterfile_table
        hash = @repo.lookup_mf_mapping(@form_object.masterfile_table)
        options_array = @repo.select_values(hash[:table_name].to_sym, [hash[:column_name].to_sym, :id])
      end
      {
        external: { renderer: :label,
                    caption: 'External system',
                    with_value: @form_object.external_system,
                    hide_on_load: @mode == :new },
        external_system: { renderer: :select,
                           caption: 'External System',
                           remove_search_for_small_list: false,
                           options: AppConst::EXTERNAL_MF_MAPPING_SYSTEMS,
                           min_charwidth: 30,
                           prompt: true,
                           required: true,
                           hide_on_load: @mode == :edit },
        mapping: { renderer: :label,
                   caption: 'Masterfile Table',
                   with_value: @form_object.mapping,
                   hide_on_load: @mode == :new  },
        masterfile_table: { renderer: :select,
                            caption: 'Masterfile Table',
                            remove_search_for_small_list: false,
                            options: @repo.for_select_external_mf_mapping,
                            min_charwidth: 30,
                            prompt: true,
                            required: true,
                            hide_on_load: @mode == :edit },
        masterfile_id: { renderer: :select,
                         caption: 'Masterfile Code',
                         remove_search_for_small_list: false,
                         options: options_array,
                         prompt: true,
                         required: true,
                         hide_on_load: @form_object.external_code.nil? },
        masterfile_code: { renderer: :label,
                           caption: 'Masterfile Code',
                           with_value: @form_object.masterfile_code,
                           hide_on_load: @form_object.mapping.nil? },
        external_code: { caption: 'External Code',
                         required: true,
                         hide_on_load: @form_object.mapping.nil? }
      }
    end

    def make_form_object
      if %i[new grid].include? @mode
        make_new_form_object
        return
      end

      @form_object = @repo.find_external_masterfile_mapping(@options[:id])
    end

    def make_new_form_object
      form_values = @options[:form_values] || {}
      hash = @repo.lookup_mf_mapping(form_values[:masterfile_table])
      masterfile_code = @repo.get(hash[:table_name].to_sym, form_values[:masterfile_id], hash[:column_name].to_sym) unless hash.empty?
      @form_object = OpenStruct.new(mapping: hash[:mapping],
                                    masterfile_table: form_values[:masterfile_table],
                                    masterfile_id: form_values[:masterfile_id],
                                    masterfile_code: masterfile_code,
                                    external_code: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :masterfile_table, notify: [{ url: '/masterfiles/general/external_masterfile_mappings/masterfile_table_changed' }]
      end
    end
  end
end
