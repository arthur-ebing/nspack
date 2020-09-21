# frozen_string_literal: true

module UiRules
  class OrganizationRule < Base
    def generate_rules
      @repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      rules[:short_too_long] = @form_object[:short_description].to_s.length <= 2
      add_behaviours if %i[new edit].include?(@mode)
      form_name 'organization'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:parent_organization] = { renderer: :label,
                                       caption: 'Parent' }
      fields[:medium_description] = { renderer: :label,
                                      caption: 'Organization Code' }
      fields[:variant_codes] = { renderer: :list,
                                 caption: 'Variant Codes',
                                 items: @form_object.variant_codes,
                                 hide_on_load: @form_object.variant_codes.empty? }
      fields[:short_description] = { renderer: :label }
      fields[:long_description] = { renderer: :label }
      fields[:vat_number] = { renderer: :label }
      fields[:company_reg_no] = { renderer: :label }
      fields[:role_names] = { renderer: :list,
                              caption: 'Roles',
                              items: @form_object.role_names.map(&:capitalize!) }
      # fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        parent_id: { renderer: :select,
                     options: @repo.for_select_organizations.reject { |i| i.include?(@options[:id]) },
                     prompt: true },
        medium_description: { caption: 'Organization Code',
                              required: true },
        short_description: { required: true },
        long_description: {},
        vat_number: {},
        company_reg_no: {},
        role_ids: { renderer: :multi,
                    options: @repo.for_select_roles,
                    selected: @form_object.role_ids,
                    required: true  }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_organization(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(short_description: nil,
                                    medium_description: nil,
                                    long_description: nil,
                                    vat_number: nil,
                                    role_ids: [])
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.keyup :short_description,
                        notify: [{ url: '/masterfiles/parties/organizations/changed/short_desc' }]
      end
    end
  end
end
