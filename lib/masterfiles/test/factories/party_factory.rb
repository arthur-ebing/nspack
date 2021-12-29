# frozen_string_literal: true

module MasterfilesApp
  module PartyFactory
    def create_person(opts = {})
      id = get_available_factory_record(:people, opts)
      return id unless id.nil?

      party_id = opts[:party_id] || DB[:parties].insert(party_type: 'P')
      default = {
        party_id: party_id,
        title: Faker::Company.name.to_s,
        first_name: Faker::Company.name.to_s,
        surname: Faker::Company.name.to_s,
        vat_number: Faker::Number.number(digits: 10),
        active: true
      }
      person_id = DB[:people].insert(default.merge(opts))
      create_party_role(person_id: person_id, party_id: party_id, name: 'TEST')
      person_id
    end

    def create_organization(opts = {})
      id = get_available_factory_record(:organizations, opts)
      return id unless id.nil?

      party_id = opts[:party_id] || DB[:parties].insert(party_type: 'O')
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
      create_party_role(organization_id: organization_id, party_id: party_id, name: 'TEST')
      organization_id
    end

    def create_role(opts = {})
      name = opts.delete(:name)
      if name
        existing_id = DB[:roles].where(name: name).get(:id)
        existing_id ||= DB[:roles].insert(name: name)
        return existing_id
      end

      id = get_available_factory_record(:roles, opts)
      return id unless id.nil?

      default = {
        name: Faker::Lorem.unique.word,
        active: true
      }
      DB[:roles].insert(default.merge(opts))
    end

    def create_party_role(opts = {})
      id = get_available_factory_record(:party_roles, opts)
      return id unless id.nil?

      opts[:role_id] ||= create_role(name: opts.delete(:name))
      party_type = opts.delete(:party_type)
      if party_type == 'P' || !opts[:person_id].nil?
        opts[:person_id] ||= create_person
        opts[:organization_id] = nil
        opts[:party_id] = DB[:people].where(id: opts[:person_id]).get(:party_id)
      else
        opts[:organization_id] ||= create_organization
        opts[:person_id] = nil
        opts[:party_id] = DB[:organizations].where(id: opts[:organization_id]).get(:party_id)
      end

      id = DB[:party_roles].where(opts).get(:id)
      return id if id

      default = {
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
      organization_id = create_organization
      party_id = DB[:organizations].where(id: organization_id).get(:party_id)
      address_id = create_address
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
      organization_id = create_organization
      party_id = DB[:organizations].where(id: organization_id).get(:party_id)
      default = {
        party_id: party_id,
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

    def create_registration(opts = {})
      party_role_id = create_party_role(party_type: 'O', name: AppConst::PARTY_ROLE_REGISTRATION_TYPES.values.first)

      default = {
        party_role_id: party_role_id,
        registration_type: AppConst::PARTY_ROLE_REGISTRATION_TYPES.keys.first,
        registration_code: Faker::Lorem.unique.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:registrations].insert(default.merge(opts))
    end

    def create_fruit_industry_levy(opts = {})
      id = get_available_factory_record(:fruit_industry_levies, opts)
      return id unless id.nil?

      default = {
        levy_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:fruit_industry_levies].insert(default.merge(opts))
    end
  end
end
