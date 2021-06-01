# frozen_string_literal: true

module MasterfilesApp
  CurrencySchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:currency).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end

  CreateCustomerSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:customer_party_role_id).filled(:string)
    optional(:short_description).maybe(Types::StrippedString)
    optional(:medium_description).maybe(Types::StrippedString)
    optional(:long_description).maybe(Types::StrippedString)
    optional(:vat_number).maybe(Types::StrippedString)
    optional(:company_reg_no).maybe(Types::StrippedString)
    required(:default_currency_id).filled(:integer)
    optional(:contact_person_ids).maybe(:array).each(:integer)
  end

  CustomerSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:default_currency_id).filled(:integer)
    required(:customer_party_role_id).filled(:integer)
    optional(:contact_person_ids).maybe(:array).each(:integer)
  end

  DealTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:deal_type).filled(Types::StrippedString)
    required(:fixed_amount).maybe(:bool)
  end

  IncotermSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:incoterm).filled(Types::StrippedString)
  end

  CustomerPaymentTermSetSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:incoterm_id).filled(:integer)
    required(:deal_type_id).filled(:integer)
    required(:customer_id).filled(:integer)
  end

  PaymentTermDateTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:type_of_date).filled(Types::StrippedString)
    required(:no_days_after_etd).maybe(:integer)
    required(:no_days_after_eta).maybe(:integer)
    required(:no_days_after_atd).maybe(:integer)
    required(:no_days_after_ata).maybe(:integer)
    required(:no_days_after_invoice).maybe(:integer)
    required(:no_days_after_invoice_sent).maybe(:integer)
    required(:no_days_after_container_load).maybe(:integer)
    required(:anchor_to_date).maybe(Types::StrippedString)
    required(:adjust_anchor_date_to_month_end).maybe(:bool)
  end

  PaymentTermTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:payment_term_type).filled(Types::StrippedString)
  end

  PaymentTermSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:payment_term_date_type_id).filled(:integer)
    required(:short_description).filled(Types::StrippedString)
    required(:long_description).maybe(Types::StrippedString)
    required(:percentage).maybe(:integer)
    required(:days).maybe(:integer)
    required(:amount_per_carton).maybe(:decimal)
    required(:for_liquidation).maybe(:bool)
  end

  CustomerPaymentTermSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:payment_term_id).filled(:integer)
    required(:customer_payment_term_set_id).filled(:integer)
  end

  OrderTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:order_type).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
