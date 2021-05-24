# frozen_string_literal: true

module Masterfiles
  module Finance
    module CustomerPaymentTermSet
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:customer_payment_term_set, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Payment Term Set'
              form.action '/list/customer_payment_term_sets'
              form.submit_captions 'Close'
              form.add_field :customer
              form.add_field :incoterm
              form.add_field :deal_type
              form.add_field :active
            end
            page.section do |section|
              section.add_grid('payment_terms',
                               '/list/payment_terms/grid_multi',
                               caption: 'Payment Terms',
                               is_multiselect: true,
                               multiselect_url: "/masterfiles/finance/customer_payment_term_sets/#{id}/link_payment_terms",
                               multiselect_key: 'customer_payment_term_set',
                               multiselect_params: { id: id,
                                                     incoterm_id: ui_rule.form_object.incoterm_id,
                                                     deal_type_id: ui_rule.form_object.deal_type_id })
            end
          end

          layout
        end
      end
    end
  end
end
