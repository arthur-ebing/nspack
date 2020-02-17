# frozen_string_literal: true

module MasterfilesApp
  module InspectorFactory
    def create_inspector(opts = {})
      inspector_party_role_id = create_party_role('P', AppConst::ROLE_INSPECTOR)

      default = {
        inspector_party_role_id: inspector_party_role_id,
        inspector_code: Faker::Lorem.unique.word,
        tablet_ip_address: Faker::Lorem.unique.word,
        tablet_port_number: Faker::Number.number(4),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspectors].insert(default.merge(opts))
    end
  end
end
