# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module MasterfilesApp
  module ChemicalFactory
    def create_chemical(opts = {})
      id = get_available_factory_record(:chemicals, opts)
      return id unless id.nil?

      default = {
        chemical_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        eu_max_level: Faker::Number.decimal,
        arfd_max_level: Faker::Number.decimal,
        orchard_chemical: false,
        drench_chemical: false,
        packline_chemical: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:chemicals].insert(default.merge(opts))
    end
  end
end
