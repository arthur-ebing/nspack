# frozen_string_literal: true

module MasterfilesApp
  module FinanceFactory # rubocop:disable Metrics/ModuleLength
    def create_customer_payment_term(opts = {})
      payment_term_id = create_payment_term
      customer_payment_term_set_id = create_customer_payment_term_set

      default = {
        payment_term_id: payment_term_id,
        customer_payment_term_set_id: customer_payment_term_set_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:customer_payment_terms].insert(default.merge(opts))
    end

    def create_payment_term(opts = {})
      payment_term_type_id = create_payment_term_type
      payment_term_date_type_id = create_payment_term_date_type

      default = {
        payment_term_type_id: payment_term_type_id,
        payment_term_date_type_id: payment_term_date_type_id,
        short_description: Faker::Lorem.unique.word,
        long_description: Faker::Lorem.word,
        percentage: Faker::Number.number(digits: 4),
        days: Faker::Number.number(digits: 4),
        amount_per_carton: Faker::Number.decimal,
        for_liquidation: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:payment_terms].insert(default.merge(opts))
    end

    def create_payment_term_type(opts = {})
      default = {
        payment_term_type: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:payment_term_types].insert(default.merge(opts))
    end

    def create_payment_term_date_type(opts = {})
      default = {
        type_of_date: Faker::Lorem.unique.word,
        no_days_after_etd: Faker::Number.number(digits: 4),
        no_days_after_eta: Faker::Number.number(digits: 4),
        no_days_after_atd: Faker::Number.number(digits: 4),
        no_days_after_ata: Faker::Number.number(digits: 4),
        no_days_after_invoice: Faker::Number.number(digits: 4),
        no_days_after_invoice_sent: Faker::Number.number(digits: 4),
        no_days_after_container_load: Faker::Number.number(digits: 4),
        anchor_to_date: Faker::Lorem.word,
        adjust_anchor_date_to_month_end: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:payment_term_date_types].insert(default.merge(opts))
    end

    def create_customer(opts = {})
      currency_id = create_currency
      party_role_id = create_party_role

      default = {
        default_currency_id: currency_id,
        customer_party_role_id: party_role_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:customers].insert(default.merge(opts))
    end

    def create_currency(opts = {})
      default = {
        currency: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:currencies].insert(default.merge(opts))
    end

    def create_deal_type(opts = {})
      default = {
        deal_type: Faker::Lorem.unique.word,
        fixed_amount: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:deal_types].insert(default.merge(opts))
    end

    def create_incoterm(opts = {})
      default = {
        incoterm: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:incoterms].insert(default.merge(opts))
    end

    def create_customer_payment_term_set(opts = {})
      incoterm_id = create_incoterm
      deal_type_id = create_deal_type
      customer_id = create_customer

      default = {
        incoterm_id: incoterm_id,
        deal_type_id: deal_type_id,
        customer_id: customer_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:customer_payment_term_sets].insert(default.merge(opts))
    end
  end
end
