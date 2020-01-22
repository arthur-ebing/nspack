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

    def test_find_party
      party_role = create_party_role('O', nil)
      party = repo.find_party(party_role[:party_id])
      assert party
      assert party.party_name
    end

    def test_create_organization
      attrs = {
        # parent_id: nil,
        short_description: Faker::Company.unique.name.to_s,
        medium_description: Faker::Company.name.to_s,
        long_description: Faker::Company.name.to_s,
        vat_number: Faker::Number.number(10),
        active: true,
        role_ids: []
      }
      result_code = repo.create_organization(attrs)
      exp = { roles: ['You did not choose a role'] }
      assert_equal exp, result_code[:error]

      role_id = create_role[:id]
      new_attrs = attrs.merge(role_ids: [role_id],
                              long_description: nil)
      result_code = repo.create_organization(new_attrs)
      org = repo.find_hash(:organizations, result_code[:id])
      medium_code = org[:medium_description]
      assert_equal medium_code, org[:long_description]

      assert repo.exists?(:parties, id: org[:party_id])
      assert repo.exists?(:party_roles,
                          party_id: org[:party_id],
                          role_id: role_id,
                          organization_id: org[:id])
    end

    #         def create_organization(attrs)
    #           params = attrs.to_h
    #           role_ids = params.delete(:role_ids)
    #           return { error: { roles: ['You did not choose a role'] } } if role_ids.empty?
    #           params[:medium_description] = params[:short_description] unless params[:medium_description]
    #           params[:long_description] = params[:short_description] unless params[:long_description]
    #           party_id = DB[:parties].insert(party_type: 'O')
    #           org_id = DB[:organizations].insert(params.merge(party_id: party_id))
    #           role_ids.each do |r_id|
    #             DB[:party_roles].insert(party_id: party_id,
    #                                     role_id: r_id,
    #                                     organization_id: org_id)
    #           end
    #           { id: org_id }
    #         end
    #
    #         def find_organization(id)
    #           hash = DB[:organizations].where(id: id).first
    #           return nil if hash.nil?
    #           hash = add_dependent_ids(hash)
    #           hash = add_party_name(hash)
    #           hash[:role_names] = DB[:roles].where(id: hash[:role_ids]).select_map(:name)
    #           parent_hash = DB[:organizations].where(id: hash[:parent_id]).first
    #           hash[:parent_organization] = parent_hash ? parent_hash[:short_description] : nil
    #           Organization.new(hash)
    #         end
    #
    #         def delete_organization(id)
    #           children = DB[:organizations].where(parent_id: id)
    #           return { error: 'This organization is set as a parent' } if children.any?
    #           party_id = party_id_from_organization(id)
    #           DB[:party_roles].where(party_id: party_id).delete
    #           DB[:organizations].where(id: id).delete
    #           delete_party_dependents(party_id)
    #           { success: true }
    #         end
    #
    #         def create_person(attrs)
    #           params = attrs.to_h
    #           role_ids = params.delete(:role_ids)
    #           return { error: 'Choose at least one role' } if role_ids.empty?
    #           party_id = DB[:parties].insert(party_type: 'P')
    #           person_id = DB[:people].insert(params.merge(party_id: party_id))
    #           role_ids.each do |r_id|
    #             DB[:party_roles].insert(party_id: party_id,
    #                                     role_id: r_id,
    #                                     person_id: person_id)
    #           end
    #           { id: person_id }
    #         end
    #
    #         def find_person(id)
    #           hash = find_hash(:people, id)
    #           return nil if hash.nil?
    #           hash = add_dependent_ids(hash)
    #           hash = add_party_name(hash)
    #           hash[:role_names] = DB[:roles].where(id: hash[:role_ids]).select_map(:name)
    #           Person.new(hash)
    #         end
    #
    #         def delete_person(id)
    #           party_id = party_id_from_person(id)
    #           DB[:party_roles].where(party_id: party_id).delete
    #           DB[:people].where(id: id).delete
    #           delete_party_dependents(party_id)
    #         end
    #
    #         def find_contact_method(id)
    #           hash = DB[:contact_methods].where(id: id).first
    #           return nil if hash.nil?
    #           contact_method_type_id = hash[:contact_method_type_id]
    #           contact_method_type_hash = DB[:contact_method_types].where(id: contact_method_type_id).first
    #           hash[:contact_method_type] = contact_method_type_hash[:contact_method_type]
    #           ContactMethod.new(hash)
    #         end
    #
    #         def find_address(id)
    #           hash = find_hash(:addresses, id)
    #           return nil if hash.nil?
    #           address_type_id = hash[:address_type_id]
    #           address_type_hash = find_hash(:address_types, address_type_id)
    #           hash[:address_type] = address_type_hash[:address_type]
    #           Address.new(hash)
    #         end
    #
    #         def delete_address(id)
    #           DB[:party_addresses].where(address_id: id).delete
    #           DB[:addresses].where(id: id).delete
    #         end
    #
    #         def link_addresses(party_id, address_ids)
    #           existing_ids      = party_address_ids(party_id)
    #           old_ids           = existing_ids - address_ids
    #           new_ids           = address_ids - existing_ids
    #
    #           DB[:party_addresses].where(party_id: party_id).where(address_id: old_ids).delete
    #           new_ids.each do |prog_id|
    #             DB[:party_addresses].insert(party_id: party_id, address_id: prog_id)
    #           end
    #         end
    #
    #         def delete_contact_method(id)
    #           DB[:party_contact_methods].where(contact_method_id: id).delete
    #           DB[:contact_methods].where(id: id).delete
    #         end
    #
    #         def link_contact_methods(party_id, contact_method_ids)
    #           existing_ids      = party_contact_method_ids(party_id)
    #           old_ids           = existing_ids - contact_method_ids
    #           new_ids           = contact_method_ids - existing_ids
    #
    #           DB[:party_contact_methods].where(party_id: party_id).where(contact_method_id: old_ids).delete
    #           new_ids.each do |prog_id|
    #             DB[:party_contact_methods].insert(party_id: party_id, contact_method_id: prog_id)
    #           end
    #         end
    #
    #         def addresses_for_party(party_id: nil, organization_id: nil, person_id: nil)
    #           id = party_id unless party_id.nil?
    #           id = party_id_from_organization(organization_id) unless organization_id.nil?
    #           id = party_id_from_person(person_id) unless person_id.nil?
    #
    #           query = <<~SQL
    #         SELECT addresses.*, address_types.address_type
    #         FROM party_addresses
    #         JOIN addresses ON addresses.id = party_addresses.address_id
    #         JOIN address_types ON address_types.id = addresses.address_type_id
    #         WHERE party_addresses.party_id = #{id}
    #           SQL
    #           DB[query].map { |r| Address.new(r) }
    #         end
    #
    #         def contact_methods_for_party(party_id: nil, organization_id: nil, person_id: nil)
    #           id = party_id unless party_id.nil?
    #           id = party_id_from_organization(organization_id) unless organization_id.nil?
    #           id = party_id_from_person(person_id) unless person_id.nil?
    #
    #           query = <<~SQL
    #         SELECT contact_methods.*, contact_method_types.contact_method_type
    #         FROM party_contact_methods
    #         JOIN contact_methods ON contact_methods.id = party_contact_methods.contact_method_id
    #         JOIN contact_method_types ON contact_method_types.id = contact_methods.contact_method_type_id
    #         WHERE party_contact_methods.party_id = #{id}
    #           SQL
    #           DB[query].map { |r| ContactMethod.new(r) }
    #         end
    #

    def test_party_id_from_organization
      org = create_organization
      actual = repo.party_id_from_organization(org[:id])
      assert_equal org[:party_id], actual
    end

    def test_party_id_from_person
      person = create_person
      actual = repo.party_id_from_person(person[:id])
      assert_equal person[:party_id], actual
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
        party_role_ids << create_party_role('O', nil, party_id: party_id)[:id]
      end
      res = repo.party_role_ids(party_id)
      assert party_role_ids.sort, res
    end

    def test_assign_roles
      role_ids = []
      4.times do
        role_ids << create_role[:id]
      end

      org_id = create_organization[:id]
      person_id = create_person[:id]

      result_code = repo.assign_roles(org_id, [], 'O')
      exp = { error: 'Choose at least one role' }
      assert_equal exp, result_code

      repo.assign_roles(org_id, role_ids, 'O')
      party_role_created = repo.where_hash(:party_roles, organization_id: org_id)
      assert party_role_created

      repo.assign_roles(person_id, role_ids, 'P')
      party_role_created = repo.where_hash(:party_roles, person_id: person_id)
      assert party_role_created
    end

    def test_create_party_role
      org = create_organization
      role_id = create_role(name: 'Given Role Name')[:id]
      repo.create_party_role(org[:party_id], 'Given Role Name')

      party_role = repo.where_hash(:party_roles, role_id: role_id)
      assert org[:party_id], party_role[:party_id]
    end

    def test_add_party_name
      party_role = create_party_role('O', nil)
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
        exp[:role_ids] << create_party_role('O', nil, party_id: party_id)[:id]
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
