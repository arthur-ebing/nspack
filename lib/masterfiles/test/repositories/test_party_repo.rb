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
      assert_respond_to repo, :for_select_fruit_industry_levies
    end

    def test_crud_calls
      test_crud_calls_for :organizations, name: :organization, wrapper: Organization
      test_crud_calls_for :people, name: :person, wrapper: Person
      test_crud_calls_for :addresses, name: :address, wrapper: Address
      test_crud_calls_for :contact_methods, name: :contact_method, wrapper: ContactMethod
      test_crud_calls_for :registrations, name: :registration, wrapper: Registration
      test_crud_calls_for :fruit_industry_levies, name: :fruit_industry_levy, wrapper: FruitIndustryLevy
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
      organization_id = create_organization
      party_id = DB[:organizations].where(id: organization_id).get(:party_id)
      address_ids = []
      4.times do
        address_ids << create_party_address(party_id: party_id)
      end
      res = repo.party_address_ids(party_id)
      assert address_ids.sort, res
    end

    def test_party_contact_method_ids
      organization_id = create_organization
      party_id = DB[:organizations].where(id: organization_id).get(:party_id)
      contact_method_ids = []
      4.times do
        contact_method_ids << create_party_contact_method(party_id: party_id)
      end
      res = repo.party_contact_method_ids(party_id)
      assert contact_method_ids.sort, res
    end

    def test_assign_roles
      role_ids = []
      4.times do
        role_ids << create_role(force_create: true)
      end

      organization_id = create_organization
      party_id = DB[:organizations].where(id: organization_id).get(:party_id)

      repo.create_party_roles(party_id, role_ids)
      party_role_created = repo.where_hash(:party_roles, party_id: party_id)
      assert party_role_created

      person_id = create_person
      party_id = repo.get(:people, :party_id, person_id)

      repo.create_party_roles(party_id, role_ids)
      party_role_created = repo.where_hash(:party_roles, party_id: party_id)
      assert party_role_created
    end

    def test_add_party_name
      organization_id = create_organization
      organization = repo.find_hash(:organizations, organization_id)
      hash = repo.find_hash(:parties, organization[:party_id])
      exp = { party_name: DB['SELECT fn_party_name(?)', organization[:party_id]].single_value }
      res = repo.send(:add_party_name, hash)
      assert exp[:party_name], res[:party_name]
    end

    def test_add_dependent_ids
      organization_id = create_organization
      party_id = DB[:organizations].where(id: organization_id).get(:party_id)
      hash = repo.find_hash(:parties, party_id)
      exp = {
        contact_method_ids: [],
        address_ids: [],
        role_ids: []
      }
      2.times do
        exp[:contact_method_ids] << create_party_contact_method(party_id: party_id)
        exp[:address_ids] << create_party_address(party_id: party_id)
        exp[:role_ids] << create_party_role(party_id: party_id)
      end
      res_hash = repo.send(:add_dependent_ids, hash)
      assert exp[:contact_method_ids], res_hash[:contact_method_ids]
      assert exp[:address_ids], res_hash[:address_ids]
      assert exp[:role_ids], res_hash[:role_ids]
    end

    def test_delete_party_dependents
      organization_id = create_organization
      party_id = DB[:organizations].where(id: organization_id).get(:party_id)
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

    private

    def repo
      PartyRepo.new
    end
  end
end
