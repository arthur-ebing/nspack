# frozen_string_literal: true

module UiRules
  class ChemicalRule < Base
    def generate_rules
      @repo = MasterfilesApp::ChemicalRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'chemical'
    end

    def set_show_fields
      fields[:chemical_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:eu_max_level] = { renderer: :label, caption: 'EU Max Level' }
      fields[:arfd_max_level] = { renderer: :label, caption: 'ARFD Max Level'  }
      fields[:orchard_chemical] = { renderer: :label, as_boolean: true }
      fields[:drench_chemical] = { renderer: :label, as_boolean: true }
      fields[:packline_chemical] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        chemical_name: { required: true },
        description: {},
        eu_max_level: { required: true, caption: 'EU Max Level' },
        arfd_max_level: { caption: 'ARFD Max Level' },
        orchard_chemical: { renderer: :checkbox },
        drench_chemical: { renderer: :checkbox },
        packline_chemical: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_chemical(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::Chemical)
      # @form_object = new_form_object_from_struct(MasterfilesApp::Chemical, merge_hash: { some_column: 'some value' })
      # @form_object = OpenStruct.new(chemical_name: nil,
      #                               description: nil,
      #                               eu_max_level: nil,
      #                               arfd_max_level: nil,
      #                               orchard_chemical: true,
      #                               drench_chemical: nil,
      #                               packline_chemical: nil)
    end

    # def handle_behaviour
    #   case @mode
    #   when :some_change_type
    #     some_change_type_change
    #   else
    #     unhandled_behaviour!
    #   end
    # end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end

    # def some_change_type_change
    #   if @params[:changed_value].empty?
    #     sel = []
    #   else
    #     sel = @repo.for_select_somethings(where: { an_id: @params[:changed_value] })
    #   end
    #   json_replace_select_options('chemical_an_id', sel)
    # end
  end
end
