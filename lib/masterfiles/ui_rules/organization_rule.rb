# frozen_string_literal: true

module UiRules
  class OrganizationRule < Base
    def generate_rules
      @repo = MasterfilesApp::PartyRepo.new
      @tm_repo = MasterfilesApp::TargetMarketRepo.new
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
                                 hide_on_load: @form_object.variant_codes&.empty? }
      fields[:short_description] = { renderer: :label }
      fields[:long_description] = { renderer: :label }
      fields[:vat_number] = { renderer: :label }
      fields[:company_reg_no] = { renderer: :label }
      fields[:specialised_role_names] = { renderer: :list,
                                          items: @form_object.specialised_role_names,
                                          hide_on_load: @form_object.specialised_role_names&.empty?,
                                          caption: 'Specialised Roles' }
      fields[:role_names] = { renderer: :list,
                              caption: 'Roles',
                              hide_on_load: @form_object.role_names&.empty?,
                              items: @form_object.role_names }
      # fields[:active] = { renderer: :label, as_boolean: true }
      fields[:target_market_ids] = { renderer: :list,
                                     caption: 'Target Markets',
                                     invisible: !show_target_markets_link(@form_object.role_names),
                                     items: @repo.target_market_names_for(@repo.party_role_id_from_role_and_party_id(AppConst::ROLE_TARGET_CUSTOMER, @form_object[:party_id])) }
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
        specialised_role_names: { renderer: :list,
                                  items: @form_object.specialised_role_names,
                                  hide_on_load: @form_object.specialised_role_names.empty?,
                                  caption: 'Specialised Roles' },
        role_ids: { renderer: :multi,
                    options: @repo.for_select_roles,
                    selected: @form_object.role_ids,
                    caption: 'Roles',
                    required: false },
        target_market_ids: { renderer: :multi,
                             options: @tm_repo.for_select_target_markets,
                             selected: @form_object.target_market_ids,
                             invisible: !show_target_markets_link(@form_object.role_names),
                             caption: 'Target Markets' }
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
                                    specialised_role_names: [],
                                    role_ids: [],
                                    target_market_ids: [])
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.keyup :short_description,
                        notify: [{ url: '/masterfiles/parties/organizations/changed/short_desc' }]
      end
    end

    def show_target_markets_link(role_names)
      return false if role_names.nil_or_empty?

      show = role_names.include?(AppConst::ROLE_TARGET_CUSTOMER)
      show = false unless AppConst::CR_PROD.kromco_target_markets_customers_link?
      show
    end
  end
end
