# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/AbcSize

module MasterfilesApp
  module PartyFactory
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
        vat_number: Faker::Number.number(10),
        active: true
      }
      {
        id: DB[:people].insert(default.merge(opts)),
        party_id: party_id
      }
    end

    def create_organization(opts = {})
      party_id = create_party(party_type: 'O')
      default = {
        party_id: party_id,
        parent_id: nil,
        short_description: Faker::Company.unique.name.to_s,
        medium_description: Faker::Company.name.to_s,
        long_description: Faker::Company.name.to_s,
        vat_number: Faker::Number.number(10),
        active: true,
        edi_hub_address: Faker::Lorem.word
      }
      {
        id: DB[:organizations].insert(default.merge(opts)),
        party_id: party_id
      }
    end

    def create_role(opts = {})
      existing_id = @fixed_table_set[:roles][:"#{opts[:name].downcase}"] if opts[:name]
      return existing_id unless existing_id.nil?

      default = {
        name: Faker::Lorem.unique.word,
        active: true
      }
      {
        id: DB[:roles].insert(default.merge(opts))
      }
    end

    def create_party_role(party_type = 'O', role = nil, opts = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      party_id = create_party(party_type: party_type)
      # role_id = opts[:role_id] || role ? create_role(name: role)[:id] : create_role[:id]
      role_id = opts[:role_id] if opts[:role_id]
      role_id = DB[:roles].where(name: role).get(:id) || create_role(name: role)[:id] if role_id.nil? && role # opts[:role_id] || role ? create_role(name: role)[:id] : create_role[:id]
      role_id = create_role[:id] if role_id.nil?
      default = {
        party_id: party_id,
        role_id: role_id,
        active: true
      }
      default[:organization_id] = create_organization(party_id: party_id)[:id] if party_type == 'O'
      default[:person_id] = create_person(party_id: party_id)[:id] if party_type == 'P'
      final_options = default.merge(opts)
      id = DB[:party_roles].insert(final_options)
      {
        id: id,
        party_id: party_id,
        organization_id: final_options[:organization_id],
        person_id: final_options[:person_id],
        role_id: role_id
      }
    end

    def create_address(opts = {})
      type_id = DB[:address_types].insert(address_type: Faker::Lorem.unique.word)
      default = {
        address_type_id: type_id,
        address_line_1: Faker::Lorem.word,
        address_line_2: Faker::Lorem.word,
        address_line_3: Faker::Lorem.word,
        city: Faker::Lorem.word,
        postal_code: Faker::Number.number(4),
        country: Faker::Lorem.word,
        active: true
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
      default = {
        party_id: create_party,
        address_id: create_address
      }
      DB[:party_addresses].insert(default.merge(opts))
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
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/AbcSize
