# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFarmGroupInteractor < MiniTestWithHooks
    include FarmsFactory
    include PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FarmRepo)
    end

    def test_farm_group
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_farm_group).returns(fake_farm_group)
      entity = interactor.send(:farm_group, 1)
      assert entity.is_a?(FarmGroup)
    end

    def test_create_farm_group
      attrs = fake_farm_group.to_h.reject { |k, _| k == :id }
      res = interactor.create_farm_group(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FarmGroup, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_farm_group_fail
      attrs = fake_farm_group(farm_group_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_farm_group(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:farm_group_code]
    end

    def test_update_farm_group
      id = create_farm_group
      attrs = interactor.send(:repo).find_hash(:farm_groups, id).reject { |k, _| k == :id }
      value = attrs[:farm_group_code]
      attrs[:farm_group_code] = 'a_change'
      res = interactor.update_farm_group(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FarmGroup, res.instance)
      assert_equal 'a_change', res.instance.farm_group_code
      refute_equal value, res.instance.farm_group_code
    end

    def test_update_farm_group_fail
      id = create_farm_group
      attrs = interactor.send(:repo).find_hash(:farm_groups, id).reject { |k, _| %i[id farm_group_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_farm_group(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:farm_group_code]
      after = interactor.send(:repo).find_hash(:farm_groups, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_farm_group
      id = create_farm_group
      assert_count_changed(:farm_groups, -1) do
        res = interactor.delete_farm_group(id)
        assert res.success, res.message
      end
    end

    private

    def farm_group_attrs
      party_role_id = create_party_role('O', AppConst::ROLE_FARM_OWNER)

      {
        id: 1,
        owner_party_role_id: party_role_id,
        farm_group_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_farm_group(overrides = {})
      FarmGroup.new(farm_group_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= FarmGroupInteractor.new(current_user, {}, {}, {})
    end
  end
end
