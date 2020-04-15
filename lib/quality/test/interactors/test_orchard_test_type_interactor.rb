# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestOrchardTestTypeInteractor < MiniTestWithHooks
    include OrchardTestFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::FarmsFactory
    include MasterfilesApp::PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(QualityApp::OrchardTestRepo)
    end

    def test_orchard_test_type
      QualityApp::OrchardTestRepo.any_instance.stubs(:find_orchard_test_type_flat).returns(fake_orchard_test_type)
      entity = interactor.send(:orchard_test_type, 1)
      assert entity.is_a?(OrchardTestType)
    end

    def test_create_orchard_test_type
      attrs = fake_orchard_test_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_orchard_test_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(OrchardTestTypeFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_orchard_test_type_fail
      attrs = fake_orchard_test_type(test_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_orchard_test_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:test_type_code]
    end

    def test_update_orchard_test_type
      id = create_orchard_test_type
      attrs = interactor.send(:repo).find_hash(:orchard_test_types, id).reject { |k, _| k == :id }
      value = attrs[:test_type_code]
      attrs[:test_type_code] = 'a_change'
      res = interactor.update_orchard_test_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(OrchardTestTypeFlat, res.instance)
      assert_equal 'a_change', res.instance.test_type_code
      refute_equal value, res.instance.test_type_code
    end

    def test_update_orchard_test_type_fail
      id = create_orchard_test_type
      attrs = interactor.send(:repo).find_hash(:orchard_test_types, id).reject { |k, _| %i[id test_type_code].include?(k) }
      res = interactor.update_orchard_test_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:test_type_code]
    end

    def test_delete_orchard_test_type
      id = create_orchard_test_type
      assert_count_changed(:orchard_test_types, -1) do
        res = interactor.delete_orchard_test_type(id)
        assert res.success, res.message
      end
    end

    private

    def orchard_test_type_attrs
      {
        id: 1,
        test_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        applies_to_all_markets: false,
        applies_to_all_cultivars: false,
        applies_to_orchard: false,
        allow_result_capturing: false,
        pallet_level_result: false,
        api_name: 'ABC',
        result_type: 'ABC',
        api_attribute: 'ABC',
        api_result_pass: 'ABC',
        applicable_tm_group_ids: [1, 2, 3],
        applicable_cultivar_ids: [1, 2, 3],
        applicable_commodity_group_ids: [1, 2, 3],
        active: true
      }
    end

    def fake_orchard_test_type(overrides = {})
      OrchardTestType.new(orchard_test_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= OrchardTestTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
