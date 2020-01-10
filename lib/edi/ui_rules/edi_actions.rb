# frozen_string_literal: true

module UiRules
  class EdiActionsRule < Base
    def generate_rules
      @repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      form_name 'ps'
    end

    def common_fields
      prs = @repo.for_select_party_roles(AppConst::ROLE_MARKETER)
      if prs.length == 1
        @form_object.party_role_id = prs.first.last
        {
          party_role_id: { renderer: :hidden },
          lbl: { renderer: :label, caption: 'Marketing Organization', with_value: prs.first.first }
        }
      else
        {
          party_role_id: { renderer: :select, caption: 'Marketing Organization', options: prs }
        }
      end
    end

    def make_form_object
      @form_object = OpenStruct.new(party_role_id: nil)
    end
  end
end
