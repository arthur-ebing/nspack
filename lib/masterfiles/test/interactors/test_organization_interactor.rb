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
      attrs = interactor.send(:repo).find_hash(:organizations, id).reject { |k, _| %i[id short_description].include?(k) }
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
      party_role_id = create_party_role('O')
      hash = interactor.send(:repo).find_hash(:party_roles, party_role_id)

      {
        id: 1,
        party_id: hash[:party_id],
        parent_id: hash[:organization_id],
        party_name: Faker::Lorem.unique.word,
        short_description: Faker::Lorem.unique.word,
        medium_description: Faker::Lorem.unique.word,
        long_description: Faker::Lorem.unique.word,
        company_reg_no: Faker::Lorem.unique.word,
        vat_number: 'ABC',
        variants: %w[A B C],
        role_ids: [hash[:role_id]],
        role_names: [Faker::Lorem.unique.word],
        variant_codes: [Faker::Lorem.unique.word],
        parent_organization: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_organization(overrides = {})
      hash = organization_attrs.merge(overrides)
      Organization.new(hash)
    end

    def interactor
      @interactor ||= OrganizationInteractor.new(current_user, {}, {}, {})
    end
  end
end
