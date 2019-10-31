# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module LabelsApp
  module MesModuleFactory
    def create_mes_module(opts = {})
      default = {
        module_code: Faker::Lorem.unique.word,
        module_type: Faker::Lorem.word,
        server_ip: nil,
        ip_address: nil,
        port: Faker::Number.number(4),
        alias: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:mes_modules].insert(default.merge(opts))
    end
  end
end
