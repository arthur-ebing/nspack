# frozen_string_literal: true

module UiRules
  class FruitActualCountsForPackRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'fruit_actual_counts_for_pack'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      std_fruit_size_count_id_label = @repo.find_hash(:std_fruit_size_counts, @form_object.std_fruit_size_count_id)[:size_count_value]
      basic_pack_code_id_label = @repo.find_hash(:basic_pack_codes, @form_object.basic_pack_code_id)[:basic_pack_code]
      fields[:std_fruit_size_count_id] = { renderer: :label, with_value: std_fruit_size_count_id_label, caption: 'Std Fruit Size Count' }
      fields[:basic_pack_code_id] = { renderer: :label, with_value: basic_pack_code_id_label, caption: 'Basic Pack Code' }
      fields[:actual_count_for_pack] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:standard_pack_codes] = { renderer: :list, items: standard_pack_codes, caption: 'Standard Packs' }
      fields[:size_references] = { renderer: :list, items: size_references }
    end

    def common_fields
      {
        std_fruit_size_count_id: { renderer: :select,
                                   options: @repo.for_select_std_fruit_size_counts,
                                   disabled_options: @repo.for_select_inactive_std_fruit_size_counts,
                                   caption: 'Std Fruit Size Count',
                                   required: true },
        basic_pack_code_id: { renderer: :select,
                              options: @repo.for_select_basic_pack_codes,
                              disabled_options: @repo.for_select_inactive_basic_pack_codes,
                              caption: 'Basic Pack Code',
                              required: true },
        actual_count_for_pack: { required: true },
        standard_pack_code_ids: { renderer: :multi,
                                  options: MasterfilesApp::FruitSizeRepo.new.for_select_standard_pack_codes,
                                  selected: @form_object.standard_pack_code_ids,
                                  caption: 'Standard Pack Codes',
                                  required: true },
        size_reference_ids: { renderer: :multi,
                              options: MasterfilesApp::FruitSizeRepo.new.for_select_fruit_size_references,
                              selected: @form_object.size_reference_ids,
                              caption: 'Size References',
                              required: true }
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

    def standard_pack_codes
      @repo.standard_pack_codes(@options[:id])
    end

    def size_references
      @repo.size_references(@options[:id])
    end
  end
end
