# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module MasterfilesApp
  module QaStandardTypeFactory
    def create_qa_standard_type(opts = {})
      id = get_available_factory_record(:qa_standard_types, opts)
      return id unless id.nil?

      default = {
        qa_standard_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:qa_standard_types].insert(default.merge(opts))
    end
  end
end
