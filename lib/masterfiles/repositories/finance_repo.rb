# frozen_string_literal: true

module MasterfilesApp
  class FinanceRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :currencies,
                     label: :currency,
                     value: :id,
                     order_by: :currency
    build_inactive_select :currencies,
                          label: :currency,
                          value: :id,
                          order_by: :currency
    crud_calls_for :currencies, name: :currency, wrapper: Currency

    build_for_select :customers,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :customers,
                          label: :id,
                          value: :id,
                          order_by: :id
    crud_calls_for :customers, name: :customer, exclude: [:delete]

    build_for_select :deal_types,
                     label: :deal_type,
                     value: :id,
                     order_by: :deal_type
    build_inactive_select :deal_types,
                          label: :deal_type,
                          value: :id,
                          order_by: :deal_type
    crud_calls_for :deal_types, name: :deal_type

    build_for_select :incoterms,
                     label: :incoterm,
                     value: :id,
                     order_by: :incoterm
    build_inactive_select :incoterms,
                          label: :incoterm,
                          value: :id,
                          order_by: :incoterm
    crud_calls_for :incoterms, name: :incoterm

    build_for_select :customer_payment_term_sets,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :customer_payment_term_sets,
                          label: :id,
                          value: :id,
                          order_by: :id
    crud_calls_for :customer_payment_term_sets, name: :customer_payment_term_set

    build_for_select :payment_term_date_types,
                     label: :type_of_date,
                     value: :id,
                     order_by: :type_of_date
    build_inactive_select :payment_term_date_types,
                          label: :type_of_date,
                          value: :id,
                          order_by: :type_of_date
    crud_calls_for :payment_term_date_types, name: :payment_term_date_type, wrapper: PaymentTermDateType

    build_for_select :payment_term_types,
                     label: :payment_term_type,
                     value: :id,
                     order_by: :payment_term_type
    build_inactive_select :payment_term_types,
                          label: :payment_term_type,
                          value: :id,
                          order_by: :payment_term_type
    crud_calls_for :payment_term_types, name: :payment_term_type, wrapper: PaymentTermType

    build_for_select :payment_terms,
                     label: :short_description,
                     value: :id,
                     order_by: :short_description
    build_inactive_select :payment_terms,
                          label: :short_description,
                          value: :id,
                          order_by: :short_description
    crud_calls_for :payment_terms, name: :payment_term

    build_for_select :customer_payment_terms,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :customer_payment_terms,
                          label: :id,
                          value: :id,
                          order_by: :id
    crud_calls_for :customer_payment_terms, name: :customer_payment_term

    build_for_select :order_types,
                     label: :order_type,
                     value: :id,
                     order_by: :order_type
    build_inactive_select :order_types,
                          label: :order_type,
                          value: :id,
                          order_by: :order_type

    crud_calls_for :order_types, name: :order_type, wrapper: OrderType

    def find_customer_payment_term(id)
      hash = find_with_association(
        :customer_payment_terms, id
      )
      return nil if hash.nil?

      hash[:payment_term] = find_payment_term(hash[:payment_term_id]).payment_term
      hash[:customer_payment_term_set] = find_customer_payment_term_set(hash[:customer_payment_term_set_id]).customer_payment_term_set

      CustomerPaymentTerm.new(hash)
    end

    def find_payment_term(id)
      hash = find_with_association(
        :payment_terms, id,
        parent_tables: [{ parent_table: :payment_term_types,
                          columns: %i[payment_term_type],
                          foreign_key: :payment_term_type_id,
                          flatten_columns: { payment_term_type: :payment_term_type } },
                        { parent_table: :payment_term_date_types,
                          columns: %i[type_of_date],
                          foreign_key: :currency_id,
                          flatten_columns: { type_of_date: :payment_term_date_type } }]
      )
      return nil if hash.nil?

      hash[:payment_term] = "#{hash[:payment_term_type]}_#{hash[:short_description]}"
      PaymentTerm.new(hash)
    end

    def find_customer(id)
      hash = find_with_association(
        :customers, id,
        parent_tables: [{ parent_table: :currencies,
                          columns: %i[currency],
                          foreign_key: :default_currency_id,
                          flatten_columns: { currency: :default_currency } }],
        lookup_functions: [{ function: :fn_current_status,
                             args: ['customers', :id],
                             col_name: :status },
                           { function: :fn_party_role_name,
                             args: [:customer_party_role_id],
                             col_name: :customer }]
      )
      return nil if hash.nil?

      hash[:contact_people] = hash[:contact_person_ids].to_a.map { |i| DB.get(Sequel.function(:fn_party_role_name, i)) }
      Customer.new(hash)
    end

    def find_deal_type(id)
      hash = find_with_association(
        :deal_types, id,
        lookup_functions: [{ function: :fn_current_status,
                             args: ['deal_types', :id],
                             col_name: :status }]
      )
      return nil if hash.nil?

      DealType.new(hash)
    end

    def find_incoterm(id)
      hash = find_with_association(
        :incoterms, id,
        lookup_functions: [{ function: :fn_current_status,
                             args: ['incoterm', :id],
                             col_name: :status }]
      )
      return nil if hash.nil?

      Incoterm.new(hash)
    end

    def find_customer_payment_term_set(id)
      hash = find_with_association(
        :customer_payment_term_sets, id,
        parent_tables: [{ parent_table: :deal_types,
                          columns: %i[deal_type],
                          foreign_key: :deal_type_id,
                          flatten_columns: { deal_type: :deal_type } },
                        { parent_table: :incoterms,
                          columns: %i[incoterm],
                          foreign_key: :incoterm_id,
                          flatten_columns: { incoterm: :incoterm } },
                        { parent_table: :customers,
                          columns: %i[customer_party_role_id],
                          foreign_key: :customer_id,
                          flatten_columns: { customer_party_role_id: :customer_party_role_id } }],
        lookup_functions: [{ function: :fn_current_status,
                             args: ['customer_payment_term_sets', :id],
                             col_name: :status }]
      )
      return nil if hash.nil?

      hash[:customer] = DB.get(Sequel.function(:fn_party_role_name, hash[:customer_party_role_id]))
      hash[:customer_payment_term_set] = "#{hash[:customer]}_#{hash[:incoterm]}_#{hash[:deal_type]}"
      CustomerPaymentTermSet.new(hash)
    end

    def delete_customer(id)
      customer_party_role_id = get(:customers, id, :customer_party_role_id)
      delete(:customers, id)
      MasterfilesApp::PartyRepo.new.delete_party_role(customer_party_role_id)
    end
  end
end
