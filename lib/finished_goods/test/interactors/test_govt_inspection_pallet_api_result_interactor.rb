# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionPalletApiResultInteractor < MiniTestWithHooks
    include GovtInspectionFactory
    include LoadFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::PackagingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::GovtInspectionRepo)
    end

    def test_govt_inspection_pallet_api_result
      skip 'pallet_factory needed'
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_pallet_api_result).returns(fake_govt_inspection_pallet_api_result)
      entity = interactor.send(:govt_inspection_pallet_api_result, 1)
      assert entity.is_a?(GovtInspectionPalletApiResult)
    end

    def test_create_govt_inspection_pallet_api_result
      skip 'pallet_factory needed'
      attrs = fake_govt_inspection_pallet_api_result.to_h.reject { |k, _| k == :id }
      res = interactor.create_govt_inspection_pallet_api_result(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GovtInspectionPalletApiResult, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_govt_inspection_pallet_api_result_fail
      skip 'pallet_factory needed'
      attrs = fake_govt_inspection_pallet_api_result(id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_govt_inspection_pallet_api_result(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:id]
    end

    def test_update_govt_inspection_pallet_api_result
      skip 'pallet_factory needed'
      id = create_govt_inspection_pallet_api_result
      attrs = interactor.send(:repo).find_hash(:govt_inspection_pallet_api_results, id).reject { |k, _| k == :id }
      value = attrs[:id]
      attrs[:id] = 'a_change'
      res = interactor.update_govt_inspection_pallet_api_result(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GovtInspectionPalletApiResult, res.instance)
      assert_equal 'a_change', res.instance.id
      refute_equal value, res.instance.id
    end

    def test_update_govt_inspection_pallet_api_result_fail
      skip 'pallet_factory needed'
      id = create_govt_inspection_pallet_api_result
      attrs = interactor.send(:repo).find_hash(:govt_inspection_pallet_api_results, id).reject { |k, _| %i[id id].include?(k) }
      res = interactor.update_govt_inspection_pallet_api_result(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:id]
    end

    def test_delete_govt_inspection_pallet_api_result
      skip 'pallet_factory needed'
      id = create_govt_inspection_pallet_api_result
      assert_count_changed(:govt_inspection_pallet_api_results, -1) do
        res = interactor.delete_govt_inspection_pallet_api_result(id)
        assert res.success, res.message
      end
    end

    private

    def govt_inspection_pallet_api_result_attrs
      govt_inspection_pallet_id = create_govt_inspection_pallet
      govt_inspection_api_result_id = create_govt_inspection_api_result

      {
        id: 1,
        passed: false,
        failure_reasons: {},
        govt_inspection_pallet_id: govt_inspection_pallet_id,
        govt_inspection_api_result_id: govt_inspection_api_result_id,
        active: true
      }
    end

    def fake_govt_inspection_pallet_api_result(overrides = {})
      GovtInspectionPalletApiResult.new(govt_inspection_pallet_api_result_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GovtInspectionPalletApiResultInteractor.new(current_user, {}, {}, {})
    end
  end
end
