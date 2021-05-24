# frozen_string_literal: true

module MasterfilesApp
  class Currency < Dry::Struct
    attribute :id, Types::Integer
    attribute :currency, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end

  class Customer < Dry::Struct
    attribute :id, Types::Integer
    attribute :default_currency_id, Types::Integer
    attribute :default_currency, Types::String
    attribute :contact_person_ids, Types::Array
    attribute :contact_people, Types::Array
    attribute :customer_party_role_id, Types::Integer
    attribute :customer, Types::String
    attribute? :active, Types::Bool
  end

  class Incoterm < Dry::Struct
    attribute :id, Types::Integer
    attribute :incoterm, Types::String
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end

  class DealType < Dry::Struct
    attribute :id, Types::Integer
    attribute :deal_type, Types::String
    attribute :fixed_amount, Types::Bool
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end

  class CustomerPaymentTermSet < Dry::Struct
    attribute :id, Types::Integer
    attribute :incoterm_id, Types::Integer
    attribute :incoterm, Types::String
    attribute :deal_type_id, Types::Integer
    attribute :deal_type, Types::String
    attribute :customer_id, Types::Integer
    attribute :customer, Types::String
    attribute :customer_payment_term_set, Types::String
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end

  class PaymentTermDateType < Dry::Struct
    attribute :id, Types::Integer
    attribute :type_of_date, Types::String
    attribute :no_days_after_etd, Types::Integer
    attribute :no_days_after_eta, Types::Integer
    attribute :no_days_after_atd, Types::Integer
    attribute :no_days_after_ata, Types::Integer
    attribute :no_days_after_invoice, Types::Integer
    attribute :no_days_after_invoice_sent, Types::Integer
    attribute :no_days_after_container_load, Types::Integer
    attribute :anchor_to_date, Types::String
    attribute :adjust_anchor_date_to_month_end, Types::Bool
    attribute? :active, Types::Bool
  end

  class PaymentTermType < Dry::Struct
    attribute :id, Types::Integer
    attribute :payment_term_type, Types::String
    attribute? :active, Types::Bool
  end

  class PaymentTerm < Dry::Struct
    attribute :id, Types::Integer
    attribute :deal_type_id, Types::Integer
    attribute :deal_type, Types::String
    attribute :incoterm_id, Types::Integer
    attribute :incoterm, Types::String
    attribute :payment_term_date_type_id, Types::Integer
    attribute :payment_term_date_type, Types::String
    attribute :payment_term, Types::String
    attribute :short_description, Types::String
    attribute :long_description, Types::String
    attribute :percentage, Types::Integer
    attribute :days, Types::Integer
    attribute :amount_per_carton, Types::Decimal
    attribute :for_liquidation, Types::Bool
    attribute? :active, Types::Bool
  end

  class CustomerPaymentTerm < Dry::Struct
    attribute :id, Types::Integer
    attribute :payment_term_id, Types::Integer
    attribute :payment_term, Types::String
    attribute :customer_payment_term_set_id, Types::Integer
    attribute :customer_payment_term_set, Types::String
    attribute? :active, Types::Bool
  end

  class OrderType < Dry::Struct
    attribute :id, Types::Integer
    attribute :order_type, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
