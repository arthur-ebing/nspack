# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestOrganizationInteractor < MiniTestWithHooks
    include PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PartyRepo)
    end

    def test_organization
      MasterfilesApp::PartyRepo.any_instance.stubs(:find_organization).returns(fake_organization)
      entity = interactor.send(:organization, 1)
      assert entity.is_a?(Organization)
    end

    def test_create_organization
      attrs = fake_organization.to_h.reject { |k, _| k == :id }
      res = interactor.create_organization(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Organization, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_organization_fail
      attrs = fake_organization(short_description: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_organization(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:short_description]
    end

    def test_update_organization
      id = create_organization
      attrs = interactor.send(:repo).find_organization(id).to_h.reject { |k, _| k == :id }
      value = attrs[:short_description]
      attrs[:short_description] = 'a_change'
      res = interactor.update_organization(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Organization, res.instance)
      assert_equal 'a_change', res.instance.short_description
      refute_equal value, res.instance.short_description
    end

    def test_update_organization_fail
      id = create_organization
      attrs = interactor.send(:repo).find_organization(id).to_h.reject { |k, _| %i[id short_description].include?(k) }
      res = interactor.update_organization(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:short_description]
    end

    def test_delete_organization
      id = create_organization
      assert_count_changed(:organizations, -1) do
        res = interactor.delete_organization(id)
        assert res.success, res.message
      end
    end

    private

    def organization_attrs
      id = create_organization
      party_id = DB[:organizations].where(id: id).get(:party_id)
      role_id = create_role
      {
        id: id,
        party_id: party_id,
        parent_id: nil,
        parent_organization: nil,
        short_description: Faker::Lorem.unique.word,
        medium_description: 'ABC',
        long_description: 'ABC',
        party_name: 'ABC',
        vat_number: 'ABC',
        edi_hub_address: 'ABC',
        company_reg_no: 'ABC',
        role_ids: [role_id],
        role_names: ['ABC'],
        specialised_role_names: ['ABC'],
        variant_codes: ['ABC'],
        active: true
      }
    end

    def fake_organization(overrides = {})
      Organization.new(organization_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= OrganizationInteractor.new(current_user, {}, {}, {})
    end
  end
end
