# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module MasterfilesApp
  module MasterfileVariantFactory
    def create_masterfile_variant(opts = {})
      default = {
        masterfile_table: Faker::Lorem.unique.word,
        code: Faker::Lorem.word,
        masterfile_id: Faker::Number.number(4),
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:masterfile_variants].insert(default.merge(opts))
    end
  end
end
