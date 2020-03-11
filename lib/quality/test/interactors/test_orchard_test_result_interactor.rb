# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestOrchardTestResultInteractor < MiniTestWithHooks
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

    def test_orchard_test_result
      QualityApp::OrchardTestRepo.any_instance.stubs(:find_orchard_test_result_flat).returns(fake_orchard_test_result)
      entity = interactor.send(:orchard_test_result, 1)
      assert entity.is_a?(OrchardTestResult)
    end

    def test_create_orchard_test_result
      attrs = fake_orchard_test_result.to_h.reject { |k, _| k == :id }
      res = interactor.create_orchard_test_result(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(OrchardTestResultFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_orchard_test_result_fail
      attrs = fake_orchard_test_result(orchard_test_type_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_orchard_test_result(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:orchard_test_type_id]
    end

    def test_update_orchard_test_result
      id = create_orchard_test_result
      attrs = interactor.send(:repo).find_hash(:orchard_test_results, id).reject { |k, _| k == :id }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_orchard_test_result(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(OrchardTestResultFlat, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_orchard_test_result_fail
      id = create_orchard_test_result
      attrs = interactor.send(:repo).find_hash(:orchard_test_results, id).reject { |k, _| %i[id description].include?(k) }
      res = interactor.update_orchard_test_result(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:description]
    end

    def test_delete_orchard_test_result
      id = create_orchard_test_result
      assert_count_changed(:orchard_test_results, -1) do
        res = interactor.delete_orchard_test_result(id)
        assert res.success, res.message
      end
    end

    private

    def orchard_test_result_attrs
      orchard_test_type_id = create_orchard_test_type
      puc_id = create_puc
      orchard_id = create_orchard
      cultivar_id = create_cultivar
      {
        id: 1,
        orchard_test_type_id: orchard_test_type_id,
        puc_id: puc_id,
        orchard_id: orchard_id,
        cultivar_id: cultivar_id,
        description: Faker::Lorem.unique.word,
        passed: false,
        classification_only: false,
        freeze_result: false,
        api_result: nil,
        classification: nil,
        applicable_from: '2010-01-01 12:00',
        applicable_to: '2010-01-01 12:00',
        active: true
      }
    end

    def fake_orchard_test_result(overrides = {})
      OrchardTestResult.new(orchard_test_result_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= OrchardTestResultInteractor.new(current_user, {}, {}, {})
    end
  end
end
