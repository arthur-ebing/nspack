# frozen_string_literal: true

module DevelopmentApp
  # UserPasswordSchema = Dry::Schema.Params do
  #   required(:password).filled(Types::StrippedString, min_size?: 4)
  #   required(:password_confirmation).filled(Types::StrippedString, min_size?: 4)
  #
  #   # rule(password_confirmation: [:password]) do |password|
  #   #   value(:password_confirmation).eql?(password)
  #   # end
  # end

  class UserPasswordContract < Dry::Validation::Contract
    params do
      required(:password).filled(Types::StrippedString, min_size?: 4)
      required(:password_confirmation).filled(Types::StrippedString, min_size?: 4)
    end

    rule(:password_confirmation, :password) do
      key.failure('must match password') if values[:password] != values[:password_confirmation]
    end
  end
end
