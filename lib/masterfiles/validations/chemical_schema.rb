# frozen_string_literal: true

module MasterfilesApp
  ChemicalSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:chemical_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:eu_max_level).filled(:decimal)
    required(:arfd_max_level).maybe(:decimal)
    required(:orchard_chemical).maybe(:bool)
    required(:drench_chemical).maybe(:bool)
    required(:packline_chemical).maybe(:bool)
  end
end
