# frozen_string_literal: true

module UiRules
  class FruitActualCountsForPackRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      add_behaviours if %i[new edit].include? @mode

      form_name 'fruit_actual_counts_for_pack'
    end

    def set_show_fields
      fields[:std_fruit_size_count] = { renderer: :label }
      fields[:basic_pack_code] = { renderer: :label, caption: 'Basic Pack' }
      fields[:actual_count_for_pack] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:standard_packs] = { renderer: :list, items: @form_object.standard_packs.split(',') }
      fields[:size_references] = { renderer: :list, items: @form_object.size_references.split(',') }
    end

    def common_fields
      {
        std_fruit_size_count_id: { renderer: :select,
                                   options: @repo.for_select_std_fruit_size_counts,
                                   disabled_options: @repo.for_select_inactive_std_fruit_size_counts,
                                   caption: 'Std Fruit Size Count',
                                   required: true },
        basic_pack_code_id: { renderer: :select,
                              options: @repo.for_select_basic_packs,
                              disabled_options: @repo.for_select_inactive_basic_packs,
                              prompt: true,
                              caption: 'Basic Pack',
                              required: true },
        actual_count_for_pack: { required: true },
        standard_pack_code_ids: { renderer: :multi,
                                  options: MasterfilesApp::FruitSizeRepo.new.for_select_standard_packs(
                                    where: { basic_pack_id: @form_object.basic_pack_code_id }
                                  ),
                                  selected: @form_object.standard_pack_code_ids,
                                  caption: 'Standard Packs',
                                  required: true },
        size_reference_ids: { renderer: :multi,
                              options: MasterfilesApp::FruitSizeRepo.new.for_select_fruit_size_references,
                              selected: @form_object.size_reference_ids,
                              caption: 'Size References' }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_fruit_actual_counts_for_pack(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(std_fruit_size_count_id: nil,
                                    basic_pack_code_id: nil,
                                    actual_count_for_pack: nil,
                                    standard_pack_code_ids: [],
                                    size_reference_ids: [])
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :basic_pack_code_id, notify: [{ url: '/masterfiles/fruit/std_fruit_size_counts/basic_pack_changed' }]
      end
    end
  end
end
