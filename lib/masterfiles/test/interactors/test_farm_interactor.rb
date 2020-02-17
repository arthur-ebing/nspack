# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFarmInteractor < MiniTestWithHooks
    include FarmsFactory
    include PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FarmRepo)
    end

    def test_farm
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_farm).returns(fake_farm)
      entity = interactor.send(:farm, 1)
      assert entity.is_a?(Farm)
    end

    def test_create_farm
      attrs = fake_farm.to_h.reject { |k, _| k == :id }
      res = interactor.create_farm(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Farm, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_farm_fail
      attrs = fake_farm(farm_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_farm(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:farm_code]
    end

    def test_update_farm
      id = create_farm
      attrs = interactor.send(:repo).find_farm(id)
      attrs = attrs.to_h
      value = attrs[:farm_code]
      attrs[:farm_code] = 'a_change'
      attrs[:puc_id] = create_puc
      res = interactor.update_farm(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Farm, res.instance)
      assert_equal 'a_change', res.instance.farm_code
      refute_equal value, res.instance.farm_code
    end

    def test_update_farm_fail
      id = create_farm
      attrs = interactor.send(:repo).find_farm(id)
      attrs = attrs.to_h
      attrs.delete(:farm_code)
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_farm(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:farm_code]
      after = interactor.send(:repo).find_farm(id)
      after = after.to_h
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_farm
      id = create_farm
      assert_count_changed(:farms, -1) do
        res = interactor.delete_farm(id)
        assert res.success, res.message
      end
    end

    private

    def farm_attrs
      party_role_id = create_party_role('O', AppConst::ROLE_FARM_OWNER)
      production_region_id = create_production_region
      farm_group_id = create_farm_group
      puc_id = create_puc

      {
        id: 1,
        owner_party_role_id: party_role_id,
        pdn_region_id: production_region_id,
        farm_group_id: farm_group_id,
        farm_code: Faker::Lorem.unique.word,
        description: 'ABC',
        puc_id: puc_id,
        farm_group_code: 'ABC',
        owner_party_role: 'ABC',
        pdn_region_production_region_code: 'ABC',
        active: true
      }
    end

    def fake_farm(overrides = {})
      Farm.new(farm_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= FarmInteractor.new(current_user, {}, {}, {})
    end
  end
end
