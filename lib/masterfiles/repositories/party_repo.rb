# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/AbcSize

module MasterfilesApp
  class PartyRepo < BaseRepo
    build_for_select :organizations,
                     label: :medium_description,
                     value: :id,
                     order_by: :medium_description
    build_for_select :people,
                     label: :surname,
                     value: :id,
                     order_by: :surname
    build_for_select :roles,
                     label: :name,
                     value: :id,
                     order_by: :name

    crud_calls_for :organizations, name: :organization, wrapper: Organization
    crud_calls_for :people, name: :person, wrapper: Person
    crud_calls_for :addresses, name: :address, wrapper: Address
    crud_calls_for :contact_methods, name: :contact_method, wrapper: ContactMethod

    def for_select_contact_method_types
      DevelopmentApp::ContactMethodTypeRepo.new.for_select_contact_method_types
    end

    def for_select_address_types
      DevelopmentApp::AddressTypeRepo.new.for_select_address_types
    end

    def find_party(id)
      hash = DB['SELECT parties.* , fn_party_name(?) AS party_name FROM parties WHERE parties.id = ?', id, id].first
      return nil if hash.nil?

      Party.new(hash)
    end

    def find_party_role(id)
      hash = DB['SELECT party_roles.* , fn_party_role_name(?) AS party_name FROM party_roles WHERE party_roles.id = ?', id, id].first
      return nil if hash.nil?

      PartyRole.new(hash)
    end

    def find_organization(id)
      hash = DB[:organizations].where(id: id).first
      return nil if hash.nil?

      hash = add_dependent_ids(hash)
      hash = add_party_name(hash)
      hash[:role_names] = DB[:roles].where(id: hash[:role_ids]).select_map(:name)
      hash[:parent_organization] = get(:organizations, hash[:parent_id], :medium_description)
      hash[:variant_codes] = select_values(:masterfile_variants, :variant_code, masterfile_id: id, masterfile_table: 'organizations')
      Organization.new(hash)
    end

    def org_code_for_party_role(id)
      DB.get(Sequel.function(:fn_party_role_org_code, id))
    end

    def fn_party_name(id)
      DB.get(Sequel.function(:fn_party_name, id))
    end

    def fn_party_role_name(id)
      DB.get(Sequel.function(:fn_party_role_name, id))
    end

    def find_organization_for_party_role(party_role_id)
      id = DB[:organizations].where(id: DB[:party_roles].where(id: party_role_id).select(:organization_id)).get(:id)
      return nil if id.nil?

      find_organization(id)
    end

    def create_organization(attrs)
      params = attrs.to_h
      role_ids = params.delete(:role_ids)

      params[:long_description] = params[:medium_description] unless params[:long_description]
      party_id = create(:parties, party_type: 'O')
      org_id = create(:organizations, params.merge(party_id: party_id))

      assign_roles(org_id, role_ids, 'O')
      org_id
    end

    def update_organization(org_id, attrs)
      params = attrs.to_h
      role_ids = params.delete(:role_ids)

      update(:organizations, org_id, params)
      assign_roles(org_id, role_ids, 'O')
    end

    def delete_organization(id)
      children = DB[:organizations].where(parent_id: id)
      raise Crossbeams::InfoError, 'This organization is set as a parent' if children.any?

      party_id = party_id_from_organization(id)
      DB[:party_roles].where(party_id: party_id).delete
      DB[:organizations].where(id: id).delete
      delete_party_dependents(party_id)
    end

    def find_person(id)
      hash = find_hash(:people, id)
      return nil if hash.nil?

      hash = add_dependent_ids(hash)
      hash = add_party_name(hash)
      hash[:role_names] = DB[:roles].where(id: hash[:role_ids]).select_map(:name)
      Person.new(hash)
    end

    def create_person(attrs)
      params = attrs.to_h
      role_ids = params.delete(:role_ids)

      party_id = create(:parties, party_type: 'P')
      person_id = create(:people, params.merge(party_id: party_id))
      assign_roles(person_id, role_ids, 'P')

      person_id
    end

    def update_person(id, attrs)
      params = attrs.to_h
      role_ids = params.delete(:role_ids)

      assign_roles(id, role_ids, 'P')
      update(:people, id, params)
    end

    def delete_person(id)
      party_id = party_id_from_person(id)
      DB[:party_roles].where(party_id: party_id).delete
      DB[:people].where(id: id).delete
      delete_party_dependents(party_id)
    end

    def find_contact_method(id)
      hash = DB[:contact_methods].where(id: id).first
      return nil if hash.nil?

      contact_method_type_id = hash[:contact_method_type_id]
      contact_method_type_hash = DB[:contact_method_types].where(id: contact_method_type_id).first
      hash[:contact_method_type] = contact_method_type_hash[:contact_method_type]
      ContactMethod.new(hash)
    end

    def find_address(id)
      hash = find_hash(:addresses, id)
      return nil if hash.nil?

      address_type_id = hash[:address_type_id]
      address_type_hash = find_hash(:address_types, address_type_id)
      hash[:address_type] = address_type_hash[:address_type]
      Address.new(hash)
    end

    def delete_address(id)
      DB[:party_addresses].where(address_id: id).delete
      DB[:addresses].where(id: id).delete
    end

    def link_addresses(party_id, address_ids)
      existing_ids      = party_address_ids(party_id)
      old_ids           = existing_ids - address_ids
      new_ids           = address_ids - existing_ids

      DB[:party_addresses].where(party_id: party_id).where(address_id: old_ids).delete
      new_ids.each do |prog_id|
        address_type_id = get(:addresses, prog_id, :address_type_id)
        DB[:party_addresses].insert(party_id: party_id, address_id: prog_id, address_type_id: address_type_id)
      end
    end

    def delete_contact_method(id)
      DB[:party_contact_methods].where(contact_method_id: id).delete
      DB[:contact_methods].where(id: id).delete
    end

    def link_contact_methods(party_id, contact_method_ids)
      existing_ids      = party_contact_method_ids(party_id)
      old_ids           = existing_ids - contact_method_ids
      new_ids           = contact_method_ids - existing_ids

      DB[:party_contact_methods].where(party_id: party_id).where(contact_method_id: old_ids).delete
      new_ids.each do |prog_id|
        DB[:party_contact_methods].insert(party_id: party_id, contact_method_id: prog_id)
      end
    end

    def addresses_for_party(party_id: nil, organization_id: nil, person_id: nil, party_role_id: nil, address_type: nil)
      id = party_id unless party_id.nil?
      id = party_id_from_organization(organization_id) unless organization_id.nil?
      id = party_id_from_person(person_id) unless person_id.nil?
      id = party_id_from_party_role(party_role_id) unless party_role_id.nil?

      query = <<~SQL
        SELECT addresses.*, address_types.address_type
        FROM party_addresses
        JOIN addresses ON addresses.id = party_addresses.address_id
        JOIN address_types ON address_types.id = addresses.address_type_id
        WHERE party_addresses.party_id = #{id}
      SQL

      addresses = DB[query].all
      addresses = addresses.select { |r| r[:address_type] == address_type } if address_type
      addresses.map { |r| MasterfilesApp::Address.new(r) }
    end

    def for_select_addresses_for_party(party_id: nil, organization_id: nil, person_id: nil, party_role_id: nil, address_type: nil)
      addresses = addresses_for_party(party_id: party_id, organization_id: organization_id, person_id: person_id, party_role_id: party_role_id, address_type: address_type)
      syms = %i[address_line_1 address_line_2 address_line_3 postal_code city country]
      address_descriptions = []
      addresses.each do |addr|
        set = []
        syms.each do |sym|
          set << addr[sym] if addr[sym]
        end
        address_descriptions << [set.join(', '), addr[:id]]
      end
      address_descriptions
    end

    def contact_methods_for_party(party_id: nil, organization_id: nil, person_id: nil)
      id = party_id unless party_id.nil?
      id = party_id_from_organization(organization_id) unless organization_id.nil?
      id = party_id_from_person(person_id) unless person_id.nil?

      query = <<~SQL
        SELECT contact_methods.*, contact_method_types.contact_method_type
        FROM party_contact_methods
        JOIN contact_methods ON contact_methods.id = party_contact_methods.contact_method_id
        JOIN contact_method_types ON contact_method_types.id = contact_methods.contact_method_type_id
        WHERE party_contact_methods.party_id = #{id}
      SQL
      DB[query].map { |r| ContactMethod.new(r) }
    end

    def party_id_from_organization(id)
      DB[:organizations].where(id: id).get(:party_id)
    end

    def party_id_from_person(id)
      DB[:people].where(id: id).get(:party_id)
    end

    def party_id_from_party_role(id)
      DB[:party_roles].where(id: id).get(:party_id)
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

    def party_role_id_from_role_and_party_id(role, party_id)
      DB[:party_roles].where(role_id: DB[:roles].where(name: role).select(:id), party_id: party_id).select_map(:id).sort
    end

    # Find the party role for the implementation owner.
    # Requires that the ENV variable "IMPLEMENTATION_OWNER" has been correctly set.
    #
    # @return [MasterfilesApp::PartyRole] the party role entity.
    #
    def implementation_owner_party_role
      query = <<~SQL
        SELECT pr.id, pr.party_id, role_id, organization_id, person_id, pr.active, fn_party_role_name(pr.id) AS party_name
        FROM public.party_roles pr
        JOIN roles r ON r.id = pr.role_id
        LEFT OUTER JOIN organizations o ON o.id = pr.organization_id
        LEFT OUTER JOIN people p ON p.id = pr.person_id
        WHERE r.name = ?
          AND COALESCE(o.medium_description, p.first_name || ' ' || p.surname) = ?
          AND pr.active
      SQL

      hash = DB[query, AppConst::ROLE_IMPLEMENTATION_OWNER, AppConst::IMPLEMENTATION_OWNER].first
      raise Crossbeams::FrameworkError, "IMPLEMENTATION OWNER \"#{AppConst::ROLE_IMPLEMENTATION_OWNER}\" is not defined/active" if hash.nil?

      PartyRole.new(hash)
    end

    def assign_roles(id, role_ids, type = 'O')
      raise Crossbeams::InfoError, 'Choose at least one role' if role_ids.empty?

      party_details = party_details_by_type(id, type)
      current_role_ids = party_details[:party_roles].select_map(:role_id)

      removed_role_ids = current_role_ids - role_ids
      party_details[:party_roles].where(role_id: removed_role_ids).delete

      new_role_ids = role_ids - current_role_ids
      new_role_ids.each do |r_id|
        DB[:party_roles].insert(
          party_id: party_details[:party_id],
          organization_id: party_details[:organization_id],
          person_id: party_details[:person_id],
          role_id: r_id
        )
      end
    end

    def append_role(id, role_id, type = 'O')
      organization_id = nil
      person_id = nil

      if type == 'P'
        party_id = DB[:people].where(id: id).get(:party_id)
        person_id = id
      end
      if type == 'O'
        party_id = DB[:organizations].where(id: id).get(:party_id)
        organization_id = id
      end
      DB[:party_roles].insert(party_id: party_id,
                              organization_id: organization_id,
                              person_id: person_id,
                              role_id: role_id)
    end

    def party_details_by_type(id, type)
      details = { organization_id: nil, person_id: nil }
      if type == 'O'
        details[:party_id] = find_organization(id).party_id
        details[:party_roles] = DB[:party_roles].where(organization_id: id)
        details[:organization_id] = id
      else
        details[:party_id] = find_person(id).party_id
        details[:party_roles] = DB[:party_roles].where(person_id: id)
        details[:person_id] = id
      end
      details
    end

    def for_select_inactive_party_roles(role)
      for_select_party_roles(role, active: false)
    end

    def for_select_party_roles(role, where: nil, active: true)
      ds = DB[:party_roles].where(role_id: DB[:roles].where(name: role).select(:id), active: active)
      ds = ds.where(where) unless where.nil?
      ds = ds.select(:id, Sequel.function(:fn_party_role_name, :id))
      ds.map { |r| [r[:fn_party_role_name], r[:id]] }
    end

    def for_select_party_roles_org_code(role, active: true)
      DB[:party_roles].where(
        role_id: DB[:roles].where(name: role).select(:id), active: active
      ).select(
        :id,
        Sequel.function(:fn_party_role_org_code, :id)
      ).map { |r| [r[:fn_party_role_org_code], r[:id]] }
    end

    def find_role_by_party_role(party_role_id)
      DB[:roles]
        .join(:party_roles, role_id: :id)
        .select(Sequel[:roles].*)
        .where(Sequel[:party_roles][:id] => party_role_id).first
    end

    def parties_except_for_role(role)
      query = <<~SQL
        SELECT fn_party_name(p.id), p.id
        FROM parties p
        WHERE NOT EXISTS(SELECT id FROM party_roles WHERE party_id = p.id AND role_id = (SELECT id FROM roles WHERE name = '#{role}'))
        AND p.active = true
      SQL
      DB[query].all.map { |r| [r[:fn_party_name] || 'Unknown party name', r[:id]] }
    end

    def email_address_for_party_role(id)
      query = <<~SQL
        SELECT contact_methods.contact_method_code
        FROM party_roles
        JOIN party_contact_methods ON party_contact_methods.party_id = party_roles.party_id
        JOIN contact_methods ON contact_methods.id = party_contact_methods.contact_method_id
        JOIN contact_method_types ON contact_method_types.id = contact_methods.contact_method_type_id
        WHERE party_roles.id = #{id}
        AND contact_method_types.contact_method_type = 'Email'
      SQL
      DB[query].get(:contact_method_code)
    end

    def find_party_role_from_party_name_for_role(party_role_name, role_name)
      role_id = DB[:roles].where(name: role_name).get(:id)
      raise Crossbeams::InfoError, "There is no role named #{role_name}" if role_id.nil?

      DB[:party_roles]
        .where(role_id: role_id, Sequel.function(:fn_party_role_name, :id) => party_role_name)
        .get(:id)
    end

    def find_party_role_from_org_code_for_role(org_code, role_name)
      role_id = DB[:roles].where(name: role_name).get(:id)
      raise Crossbeams::InfoError, "There is no role named #{role_name}" if role_id.nil?

      DB[:party_roles]
        .where(role_id: role_id, Sequel.function(:fn_party_role_org_code, :id) => org_code)
        .get(:id)
    end

    private

    def add_party_name(hash)
      party_id = hash[:party_id]
      hash[:party_name] = DB['SELECT fn_party_name(?)', party_id].single_value
      hash
    end

    def add_dependent_ids(hash)
      party_id = hash[:party_id]
      hash[:contact_method_ids] = party_contact_method_ids(party_id)
      hash[:address_ids] = party_address_ids(party_id)
      hash[:role_ids] = party_role_ids(party_id)
      hash
    end

    def delete_party_dependents(party_id)
      DB[:party_addresses].where(party_id: party_id).delete
      DB[:party_contact_methods].where(party_id: party_id).delete
      DB[:parties].where(id: party_id).delete
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/AbcSize
