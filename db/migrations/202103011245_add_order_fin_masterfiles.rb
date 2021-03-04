require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:currencies, ignore_index_errors: true) do
      primary_key :id
      String :currency, null: false
      String :description

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      unique :currency
    end

    pgt_created_at(:currencies,
                   :created_at,
                   function_name: :currencies_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:currencies,
                   :updated_at,
                   function_name: :currencies_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('currencies', true, true, '{updated_at}'::text[]);"


    create_table(:deal_types, ignore_index_errors: true) do
      primary_key :id
      String :deal_type, null: false
      TrueClass :fixed_amount, default: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      unique :deal_type
    end

    pgt_created_at(:deal_types,
                   :created_at,
                   function_name: :deal_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:deal_types,
                   :updated_at,
                   function_name: :deal_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('deal_types', true, true, '{updated_at}'::text[]);"

    create_table(:incoterms, ignore_index_errors: true) do
      primary_key :id
      String :incoterm, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      unique :incoterm
    end

    pgt_created_at(:incoterms,
                   :created_at,
                   function_name: :incoterms_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:incoterms,
                   :updated_at,
                   function_name: :incoterms_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('incoterms', true, true, '{updated_at}'::text[]);"

    create_table(:customers, ignore_index_errors: true) do
      primary_key :id
      foreign_key :default_currency_id, :currencies, type: :integer, null: false
      foreign_key :customer_party_role_id, :party_roles, type: :integer, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique :customer_party_role_id
    end

    pgt_created_at(:customers,
                   :created_at,
                   function_name: :customers_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:customers,
                   :updated_at,
                   function_name: :customers_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('customers', true, true, '{updated_at}'::text[]);"

    run "UPDATE roles SET specialised = TRUE WHERE name = 'CUSTOMER';"

    create_table(:customer_payment_term_sets, ignore_index_errors: true) do
      primary_key :id
      foreign_key :incoterm_id, :incoterms, type: :integer, null: false
      foreign_key :deal_type_id, :deal_types, type: :integer, null: false
      foreign_key :customer_id, :customers, type: :integer, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique [:incoterm_id, :deal_type_id, :customer_id]
    end

    pgt_created_at(:customer_payment_term_sets,
                   :created_at,
                   function_name: :customer_payment_term_sets_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:customer_payment_term_sets,
                   :updated_at,
                   function_name: :customer_payment_term_sets_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('customer_payment_term_sets', true, true, '{updated_at}'::text[]);"

    create_table(:payment_term_date_types, ignore_index_errors: true) do
      primary_key :id
      String :type_of_date, null: false
      Integer :no_days_after_etd
      Integer :no_days_after_eta
      Integer :no_days_after_atd
      Integer :no_days_after_ata
      Integer :no_days_after_invoice
      Integer :no_days_after_invoice_sent
      Integer :no_days_after_container_load
      String :anchor_to_date
      TrueClass :adjust_anchor_date_to_month_end, default: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique :type_of_date
    end

    pgt_created_at(:payment_term_date_types,
                   :created_at,
                   function_name: :payment_term_date_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:payment_term_date_types,
                   :updated_at,
                   function_name: :payment_term_date_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('payment_term_date_types', true, true, '{updated_at}'::text[]);"

    create_table(:payment_term_types, ignore_index_errors: true) do
      primary_key :id
      String :payment_term_type, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique :payment_term_type
    end

    pgt_created_at(:payment_term_types,
                   :created_at,
                   function_name: :payment_term_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:payment_term_types,
                   :updated_at,
                   function_name: :payment_term_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('payment_term_types', true, true, '{updated_at}'::text[]);"

    create_table(:payment_terms, ignore_index_errors: true) do
      primary_key :id
      foreign_key :payment_term_type_id, :payment_term_types, type: :integer, null: false
      foreign_key :payment_term_date_type_id, :payment_term_date_types, type: :integer, null: false
      String :short_description, null: false
      String :long_description
      Integer :percentage
      Integer :days
      Decimal :amount_per_carton
      TrueClass :for_liquidation, default: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique [:payment_term_type_id, :payment_term_date_type_id]
    end

    pgt_created_at(:payment_terms,
                   :created_at,
                   function_name: :payment_terms_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:payment_terms,
                   :updated_at,
                   function_name: :payment_terms_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('payment_terms', true, true, '{updated_at}'::text[]);"

    create_table(:customer_payment_terms, ignore_index_errors: true) do
      primary_key :id
      foreign_key :payment_term_id, :payment_terms, type: :integer, null: false
      foreign_key :customer_payment_term_set_id, :customer_payment_term_sets, type: :integer, null: false

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      unique [:payment_term_id, :customer_payment_term_set_id]
    end

    pgt_created_at(:customer_payment_terms,
                   :created_at,
                   function_name: :customer_payment_terms_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:customer_payment_terms,
                   :updated_at,
                   function_name: :customer_payment_terms_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('customer_payment_terms', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:customer_payment_terms, :audit_trigger_row)
    drop_trigger(:customer_payment_terms, :audit_trigger_stm)

    drop_trigger(:customer_payment_terms, :set_created_at)
    drop_function(:customer_payment_terms_set_created_at)
    drop_trigger(:customer_payment_terms, :set_updated_at)
    drop_function(:customer_payment_terms_set_updated_at)
    drop_table :customer_payment_terms

    drop_trigger(:payment_terms, :audit_trigger_row)
    drop_trigger(:payment_terms, :audit_trigger_stm)

    drop_trigger(:payment_terms, :set_created_at)
    drop_function(:payment_terms_set_created_at)
    drop_trigger(:payment_terms, :set_updated_at)
    drop_function(:payment_terms_set_updated_at)
    drop_table :payment_terms

    drop_trigger(:payment_term_types, :audit_trigger_row)
    drop_trigger(:payment_term_types, :audit_trigger_stm)

    drop_trigger(:payment_term_types, :set_created_at)
    drop_function(:payment_term_types_set_created_at)
    drop_trigger(:payment_term_types, :set_updated_at)
    drop_function(:payment_term_types_set_updated_at)
    drop_table :payment_term_types

    drop_trigger(:payment_term_date_types, :audit_trigger_row)
    drop_trigger(:payment_term_date_types, :audit_trigger_stm)

    drop_trigger(:payment_term_date_types, :set_created_at)
    drop_function(:payment_term_date_types_set_created_at)
    drop_trigger(:payment_term_date_types, :set_updated_at)
    drop_function(:payment_term_date_types_set_updated_at)
    drop_table :payment_term_date_types

    drop_trigger(:customer_payment_term_sets, :audit_trigger_row)
    drop_trigger(:customer_payment_term_sets, :audit_trigger_stm)

    drop_trigger(:customer_payment_term_sets, :set_created_at)
    drop_function(:customer_payment_term_sets_set_created_at)
    drop_trigger(:customer_payment_term_sets, :set_updated_at)
    drop_function(:customer_payment_term_sets_set_updated_at)
    drop_table :customer_payment_term_sets

    run "UPDATE roles SET specialised = FALSE WHERE name = 'CUSTOMER';"

    drop_trigger(:customers, :audit_trigger_row)
    drop_trigger(:customers, :audit_trigger_stm)

    drop_trigger(:customers, :set_created_at)
    drop_function(:customers_set_created_at)
    drop_trigger(:customers, :set_updated_at)
    drop_function(:customers_set_updated_at)
    drop_table :customers

    drop_trigger(:incoterms, :audit_trigger_row)
    drop_trigger(:incoterms, :audit_trigger_stm)

    drop_trigger(:incoterms, :set_created_at)
    drop_function(:incoterms_set_created_at)
    drop_trigger(:incoterms, :set_updated_at)
    drop_function(:incoterms_set_updated_at)
    drop_table :incoterms

    drop_trigger(:deal_types, :audit_trigger_row)
    drop_trigger(:deal_types, :audit_trigger_stm)

    drop_trigger(:deal_types, :set_created_at)
    drop_function(:deal_types_set_created_at)
    drop_trigger(:deal_types, :set_updated_at)
    drop_function(:deal_types_set_updated_at)
    drop_table :deal_types

    drop_trigger(:currencies, :audit_trigger_row)
    drop_trigger(:currencies, :audit_trigger_stm)

    drop_trigger(:currencies, :set_created_at)
    drop_function(:currencies_set_created_at)
    drop_trigger(:currencies, :set_updated_at)
    drop_function(:currencies_set_updated_at)
    drop_table :currencies
  end
end
