# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMrlRequirementInteractor < MiniTestWithHooks
    include MrlRequirementFactory
    include PartyFactory
    include CalendarFactory
    include TargetMarketFactory
    include FruitFactory
    include CommodityFactory
    include CultivarFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::MrlRequirementRepo)
    end

    def test_mrl_requirement
      MasterfilesApp::MrlRequirementRepo.any_instance.stubs(:find_mrl_requirement).returns(fake_mrl_requirement)
      entity = interactor.send(:mrl_requirement, 1)
      assert entity.is_a?(MrlRequirement)
    end

    def test_create_mrl_requirement
      attrs = fake_mrl_requirement.to_h.reject { |k, _| k == :id }
      attrs[:cultivar_group_id] = nil
      attrs[:qa_standard_id] = nil
      attrs[:packed_tm_group_id] = nil
      attrs[:target_market_id] = nil
      res = interactor.create_mrl_requirement(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MrlRequirement, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_mrl_requirement_fail
      attrs = fake_mrl_requirement(id: nil).to_h.reject { |k, _| k == :id }
      attrs[:max_num_chemicals_allowed] = nil
      attrs[:cultivar_group_id] = nil
      attrs[:qa_standard_id] = nil
      attrs[:packed_tm_group_id] = nil
      attrs[:target_market_id] = nil
      res = interactor.create_mrl_requirement(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:max_num_chemicals_allowed]
    end

    def test_update_mrl_requirement
      id = create_mrl_requirement
      attrs = interactor.send(:repo).find_hash(:mrl_requirements, id).reject { |k, _| k == :max_num_chemicals_allowed }
      value = attrs[:max_num_chemicals_allowed]
      attrs[:max_num_chemicals_allowed] = 23
      attrs[:cultivar_group_id] = nil
      attrs[:qa_standard_id] = nil
      attrs[:packed_tm_group_id] = nil
      attrs[:target_market_id] = nil
      res = interactor.update_mrl_requirement(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MrlRequirement, res.instance)
      assert_equal 23, res.instance.max_num_chemicals_allowed
      refute_equal value, res.instance.max_num_chemicals_allowed
    end

    def test_update_mrl_requirement_fail
      id = create_mrl_requirement
      attrs = interactor.send(:repo).find_hash(:mrl_requirements, id).reject { |k, _| %i[id max_num_chemicals_allowed].include?(k) }
      res = interactor.update_mrl_requirement(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:max_num_chemicals_allowed]
    end

    def test_delete_mrl_requirement
      id = create_mrl_requirement(force_create: true)
      assert_count_changed(:mrl_requirements, -1) do
        res = interactor.delete_mrl_requirement(id)
        assert res.success, res.message
      end
    end

    private

    def mrl_requirement_attrs
      season_id = create_season
      qa_standard_id = create_qa_standard
      target_market_group_id = create_target_market_group
      target_market_id = create_target_market
      party_role_id = create_party_role
      cultivar_group_id = create_cultivar_group
      cultivar_id = create_cultivar

      {
        id: 1,
        season_id: season_id,
        qa_standard_id: qa_standard_id,
        packed_tm_group_id: target_market_group_id,
        target_market_id: target_market_id,
        target_customer_id: party_role_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_id: cultivar_id,
        max_num_chemicals_allowed: 1,
        require_orchard_level_results: false,
        no_results_equal_failure: false,
        active: true
      }
    end

    def fake_mrl_requirement(overrides = {})
      MrlRequirement.new(mrl_requirement_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= MrlRequirementInteractor.new(current_user, {}, {}, {})
    end
  end
end
