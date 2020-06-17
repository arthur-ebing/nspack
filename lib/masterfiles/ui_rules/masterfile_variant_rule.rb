# frozen_string_literal: true

module UiRules
  class MasterfileVariantRule < Base
    def generate_rules
      @repo = MasterfilesApp::MasterfileVariantRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      add_behaviours if %i[new].include? @mode

      set_show_fields if %i[show].include? @mode

      form_name 'masterfile_variant'
    end

    def set_show_fields
      fields[:masterfile_table] = { renderer: :label,
                                    with_value: @form_object.variant,
                                    caption: 'Variant' }
      fields[:variant_code] = { renderer: :label,
                                caption: 'Variant Code' }
      fields[:masterfile_id] = { renderer: :label }
      fields[:masterfile_code] = { renderer: :label,
                                   with_value: @form_object.masterfile_code }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      if @form_object.masterfile_table
        hash = @repo.lookup_mf_variant(@form_object.masterfile_table)
        options_array = @repo.select_values(hash[:table_name].to_sym, [hash[:column].to_sym, :id])
      end
      {
        masterfile_table: { renderer: @mode == :edit ? :label : :select,
                            caption: 'Variant',
                            remove_search_for_small_list: false,
                            options: @repo.for_select_mf_variant,
                            with_value: @form_object.variant,
                            min_charwidth: 30,
                            prompt: true,
                            required: true },
        masterfile_id: { renderer: @mode == :edit ? :label : :select,
                         caption: 'Masterfile Code',
                         remove_search_for_small_list: false,
                         options: options_array,
                         with_value: @form_object.masterfile_code,
                         prompt: true,
                         required: true,
                         hide_on_load: @form_object.masterfile_table.nil? },
        variant_code: { caption: 'Variant Code',
                        required: true,
                        hide_on_load: @form_object.masterfile_table.nil? }
      }
    end

    def make_form_object
      if %i[new grid].include? @mode
        make_new_form_object
        return
      end

      @form_object = @repo.find_masterfile_variant_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(masterfile_table: nil,
                                    code: nil,
                                    masterfile_id: nil,
                                    masterfile_code: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :masterfile_table, notify: [{ url: '/masterfiles/general/masterfile_variants/masterfile_table_changed' }]
      end
    end
  end
end
