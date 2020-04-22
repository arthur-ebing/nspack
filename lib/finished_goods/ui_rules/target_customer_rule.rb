# frozen_string_literal: true

module UiRules
  class TargetCustomerRule < Base
    def generate_rules
      @repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      form_name 'target_customer'
    end

    def common_fields
      target_customers = @repo.for_select_party_roles(AppConst::ROLE_TARGET_CUSTOMER)
      rules[:notice] = 'There are no target customer party roles' if target_customers.empty?
      {
        target_customer_party_role_id: { renderer: :select,
                                         options: target_customers,
                                         disabled_options: @repo.for_select_inactive_party_roles(AppConst::ROLE_TARGET_CUSTOMER),
                                         caption: 'Target Customer',
                                         required: true,
                                         invisible: target_customers.empty? }
      }
    end

    def make_form_object
      @form_object = OpenStruct.new(target_customer_party_role_id: nil)
    end
  end
end
