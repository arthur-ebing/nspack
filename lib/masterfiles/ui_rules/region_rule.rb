# frozen_string_literal: true

module UiRules
  class RegionRule < Base
    def generate_rules
      @repo = MasterfilesApp::DestinationRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'region'
    end

    def set_show_fields
      fields[:destination_region_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:tm_groups] = { renderer: :list, items: tm_group_names }
    end

    def common_fields
      {
        destination_region_name: { required: true },
        description: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_region(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(destination_region_name: nil,
                                    description: nil)
    end

    def tm_group_names
      @repo.find_region_tm_group_names(@options[:id])
    end
  end
end
