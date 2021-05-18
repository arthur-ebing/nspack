# frozen_string_literal: true

module Masterfiles
  module Finance
    module CustomerPaymentTermSet
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:customer_payment_term_set, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Payment Term Set'
              form.action "/masterfiles/finance/customer_payment_term_sets/#{id}"
              form.remote!
              form.method :update
              form.add_field :customer_id
              form.add_field :customer
              form.add_field :incoterm_id
              form.add_field :deal_type_id
            end
            page.section do |section|
              section.add_grid('payment_terms',
                               '/list/payment_terms/grid_multi',
                               caption: 'Payment Terms',
                               is_multiselect: true,
                               multiselect_url: "/masterfiles/finance/customer_payment_term_sets/#{id}/link_payment_terms",
                               multiselect_key: 'customer_payment_term_set',
                               multiselect_params: { id: id })
            end
          end

          layout
        end
      end
    end
  end
end
