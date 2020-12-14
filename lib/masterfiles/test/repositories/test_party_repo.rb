# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')
require File.join(File.expand_path('../factories', __dir__), 'party_factory')

module MasterfilesApp
  class TestPartyRepo < MiniTestWithHooks
    include PartyFactory

    def test_for_selects
      assert_respond_to repo, :for_select_organizations
      assert_respond_to repo, :for_select_people
      assert_respond_to repo, :for_select_roles

      assert_respond_to repo, :for_select_contact_method_types
      assert_respond_to repo, :for_select_address_types
    end

    def test_crud_calls
      test_crud_calls_for :organizations, name: :organization, wrapper: Organization
      test_crud_calls_for :people, name: :person, wrapper: Person
      test_crud_calls_for :addresses, name: :address, wrapper: Address
      test_crud_calls_for :contact_methods, name: :contact_method, wrapper: ContactMethod
    end

    def test_create_organization
      attrs = {
        # parent_id: nil,
        short_description: Faker::Company.unique.name.to_s,
        medium_description: Faker::Company.name.to_s,
        long_description: Faker::Company.name.to_s,
        vat_number: Faker::Number.number(digits: 10),
        active: true,
        role_ids: []
      }

      role_id = create_role
      new_attrs = attrs.merge(role_ids: [role_id],
                              long_description: nil)
      org_id = repo.create_organization(new_attrs)
      org = repo.find_hash(:organizations, org_id)
      medium_code = org[:medium_description]
      assert_equal medium_code, org[:long_description]

      assert repo.exists?(:parties, id: org[:party_id])
      assert repo.exists?(:party_roles,
                          party_id: org[:party_id],
                          role_id: role_id,
                          organization_id: org[:id])
    end

    def test_party_address_ids
      party_id = create_party
      address_ids = []
      4.times do
        address_ids << create_party_address(party_id: party_id)
      end
      res = repo.party_address_ids(party_id)
      assert address_ids.sort, res
    end

    def test_party_contact_method_ids
      party_id = create_party
      contact_method_ids = []
      4.times do
        contact_method_ids << create_party_contact_method(party_id: party_id)
      end
      res = repo.party_contact_method_ids(party_id)
      assert contact_method_ids.sort, res
    end

    def test_party_role_ids
      party_id = create_party
      party_role_ids = []
      4.times do
        party_role_ids << create_party_role('O', nil, party_id: party_id)
      end
      res = repo.party_role_ids(party_id)
      assert party_role_ids.sort, res
    end

    def test_assign_roles
      role_ids = []
      4.times do
        role_ids << create_role
      end

      org_id = create_organization
      person_id = create_person

      repo.assign_roles(org_id, role_ids, 'O')
      party_role_created = repo.where_hash(:party_roles, organization_id: org_id)
      assert party_role_created

      repo.assign_roles(person_id, role_ids, 'P')
      party_role_created = repo.where_hash(:party_roles, person_id: person_id)
      assert party_role_created
    end

    def test_add_party_name
      party_role_id = create_party_role('O')
      party_role = repo.find_hash(:party_roles, party_role_id)
      hash = repo.find_hash(:parties, party_role[:party_id])
      exp = { party_name: DB['SELECT fn_party_name(?)', party_role[:party_id]].single_value }
      res = repo.send(:add_party_name, hash)
      assert exp[:party_name], res[:party_name]
    end

    def test_add_dependent_ids
      party_id = create_party
      hash = repo.find_hash(:parties, party_id)
      exp = {
        contact_method_ids: [],
        address_ids: [],
        role_ids: []
      }
      2.times do
        exp[:contact_method_ids] << create_party_contact_method(party_id: party_id)
        exp[:address_ids] << create_party_address(party_id: party_id)
        exp[:role_ids] << create_party_role('O', nil, party_id: party_id)
      end
      res_hash = repo.send(:add_dependent_ids, hash)
      assert exp[:contact_method_ids], res_hash[:contact_method_ids]
      assert exp[:address_ids], res_hash[:address_ids]
      assert exp[:role_ids], res_hash[:role_ids]
    end

    def test_delete_party_dependents
      party_id = create_party
      party_address_id = create_party_address(party_id: party_id)
      party_contact_method_id = create_party_contact_method(party_id: party_id)
      assert repo.find_hash(:party_addresses, party_address_id)
      assert repo.find_hash(:party_contact_methods, party_contact_method_id)
      assert repo.find_hash(:parties, party_id)

      repo.send(:delete_party_dependents, party_id)
      refute repo.find_hash(:party_addresses, party_address_id)
      refute repo.find_hash(:party_contact_methods, party_contact_method_id)
      refute repo.find_hash(:parties, party_id)
    end

    def test_factories
      create_organization
      create_role
      create_party
      create_party_role
      create_person
      create_address
      create_contact_method
      create_party_address
      create_party_contact_method
    end

    private

    def repo
      PartyRepo.new
    end
  end
end
