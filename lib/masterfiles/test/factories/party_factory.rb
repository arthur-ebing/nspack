# frozen_string_literal: true

module MasterfilesApp
  module PartyFactory # rubocop:disable Metrics/ModuleLength
    def create_party(opts = {})
      opts[:party_type] ||= 'O'
      DB[:parties].insert(opts)
    end

    def create_person(opts = {})
      party_id = opts[:party_id] || create_party(party_type: 'P')

      default = {
        party_id: party_id,
        title: Faker::Company.name.to_s,
        first_name: Faker::Company.name.to_s,
        surname: Faker::Company.name.to_s,
        vat_number: Faker::Number.number(digits: 10),
        active: true
      }
      person_id = DB[:people].insert(default.merge(opts))
      create_party_role(party_id: party_id)
      person_id
    end

    def create_organization(opts = {})
      party_id = opts[:party_id] || create_party(party_type: 'O')
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
      create_party_role(party_id: party_id)
      organization_id
    end

    def create_role(opts = {})
      if opts[:name]
        existing_id = DB[:roles].where(name: opts[:name]).get(:id)
        return existing_id if existing_id
      end

      default = {
        name: Faker::Lorem.unique.word,
        active: true
      }
      DB[:roles].insert(default.merge(opts))
    end

    def create_party_role(opts = {}) # rubocop:disable Metrics/AbcSize
      opts[:party_id] ||= create_party(party_type: opts.delete(:party_type))
      opts[:role_id] ||= create_role(name: opts.delete(:name))
      organization_id = DB[:organizations].where(party_id: opts[:party_id]).get(:id)
      person_id = DB[:people].where(party_id: opts[:party_id]).get(:id)

      default = {
        organization_id: organization_id,
        person_id: person_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
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

    def party_address_ids(party_id)
      DB[:party_addresses].where(party_id: party_id).select_map(:address_id).sort
    end

    def party_contact_method_ids(party_id)
      DB[:party_contact_methods].where(party_id: party_id).select_map(:contact_method_id).sort
    end

    def party_role_ids(party_id)
      DB[:party_roles].where(party_id: party_id).select_map(:role_id).sort
    end
  end
end
