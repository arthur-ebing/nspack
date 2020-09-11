# frozen_string_literal: true

module EdiApp
  EdiPalbinInSchema = Dry::Schema.Params do
    required(:destination).filled(Types::StrippedString)
    required(:depot).filled(Types::StrippedString)
    required(:sscc).filled(Types::StrippedString)
    required(:farm).filled(Types::StrippedString)
    required(:puc).filled(Types::StrippedString)
    required(:orchard).filled(Types::StrippedString)
    required(:cultivar).filled(Types::StrippedString)
    required(:commodity).filled(Types::StrippedString)
    required(:grade).filled(Types::StrippedString)
    required(:pack).filled(Types::StrippedString)
    required(:size_reference).filled(Types::StrippedString)
    required(:shipped_at).maybe(:time)
    required(:gross_weight).maybe(:decimal)
    required(:nett_weight).maybe(:decimal)
  end
end
