# frozen_string_literal: true

module MasterfilesApp
  module PartyFactory # rubocop:disable Metrics/ModuleLength
    def create_party(opts = {})
      default = {
        party_type: 'O', # || 'P'
        active: true
      }
      DB[:parties].insert(default.merge(opts))
    end

    def create_person(opts = {})
      party_id = create_party(party_type: 'P')
      default = {
        party_id: party_id,
        title: Faker::Company.name.to_s,
        first_name: Faker::Company.name.to_s,
        surname: Faker::Company.name.to_s,
        vat_number: Faker::Number.number(digits: 10),
        active: true
      }
      DB[:people].insert(default.merge(opts))
    end

    def create_organization(opts = {})
      party_id = create_party(party_type: 'O')
      default = {
        party_id: party_id,
        parent_id: nil,
        short_description: Faker::Company.unique.name.to_s,
        medium_description: Faker::Company.name.to_s,
        long_description: Faker::Company.name.to_s,
        vat_number: Faker::Number.number(digits: 10),
        active: true
      }
      organization_id = DB[:organizations].insert(default.merge(opts))

      create_party_role('O', nil, organization_id: organization_id)
      organization_id
    end

    def create_role(opts = {})
      existing_id = @fixed_table_set[:roles][:"#{opts[:name].downcase}"] if opts[:name]
      return existing_id unless existing_id.nil?

      default = { name: Faker::Lorem.unique.word, active: true }
      DB[:roles].insert(default.merge(opts))
    end

    def create_party_role(party_type = 'O', role_name = nil, opts = {}) # rubocop:disable Metrics/AbcSize
      default = { active: true }
      if party_type == 'O'
        default[:organization_id] = opts[:organization_id] || create_organization
        default[:party_id] = DB[:organizations].where(id: default[:organization_id]).get(:party_id)
      end
      if party_type == 'P'
        default[:person_id] = opts[:person_id] || create_person
        default[:party_id] = DB[:people].where(id: default[:person_id]).get(:party_id)
      end
      default[:role_id] = DB[:roles].where(name: role_name).get(:id) || create_role

      DB[:party_roles].insert(default.merge(opts))
    end

    def create_address(opts = {})
      address_type_id = create_address_type

      default = {
        address_type_id: address_type_id,
        address_line_1: Faker::Lorem.unique.word,
        address_line_2: Faker::Lorem.word,
        address_line_3: Faker::Lorem.word,
        city: Faker::Lorem.word,
        postal_code: Faker::Lorem.word,
        country: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:addresses].insert(default.merge(opts))
    end

    def create_contact_method(opts = {})
      type_id = DB[:contact_method_types].insert(contact_method_type: Faker::Lorem.unique.word)
      default = {
        contact_method_type_id: type_id,
        contact_method_code: Faker::Lorem.word,
        active: true
      }
      DB[:contact_methods].insert(default.merge(opts))
    end

    def create_party_address(opts = {})
      address_id = create_address
      party_id = create_party
      address_type_id = create_address_type

      default = {
        address_id: address_id,
        party_id: party_id,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        address_type_id: address_type_id
      }
      DB[:party_addresses].insert(default.merge(opts))
    end

    def create_address_type(opts = {})
      default = {
        address_type: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:address_types].insert(default.merge(opts))
    end

    def create_party_contact_method(opts = {})
      default = {
        party_id: create_party,
        contact_method_id: create_contact_method
      }
      DB[:party_contact_methods].insert(default.merge(opts))
    end
  end
end
