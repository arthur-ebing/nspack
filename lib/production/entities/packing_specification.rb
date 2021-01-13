# frozen_string_literal: true

module ProductionApp
  class PackingSpecification < Dry::Struct
    attribute :id, Types::Integer
    attribute :product_setup_template_id, Types::Integer
    attribute :product_setup_template, Types::String
    attribute :packing_specification_code, Types::String
    attribute :description, Types::String
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end
end
