# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionApiResultInteractor < MiniTestWithHooks
    include GovtInspectionFactory
    include LoadFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::DepotFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::GovtInspectionApiResultRepo)
    end

    def test_govt_inspection_api_result
      skip 'pallet_factory needed'
      FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(fake_govt_inspection_api_result)
      entity = interactor.send(:govt_inspection_api_result, 1)
      assert entity.is_a?(GovtInspectionApiResult)
    end

    def test_create_govt_inspection_api_result
      skip 'pallet_factory needed'
      attrs = fake_govt_inspection_api_result.to_h.reject { |k, _| k == :id }
      res = interactor.create_govt_inspection_api_result(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GovtInspectionApiResult, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_govt_inspection_api_result_fail
      skip 'pallet_factory needed'
      attrs = fake_govt_inspection_api_result(upn_number: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_govt_inspection_api_result(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:upn_number]
    end

    def test_update_govt_inspection_api_result
      skip 'pallet_factory needed'
      id = create_govt_inspection_api_result
      attrs = interactor.send(:repo).find_hash(:govt_inspection_api_results, id).reject { |k, _| k == :id }
      value = attrs[:upn_number]
      attrs[:upn_number] = 'a_change'
      res = interactor.update_govt_inspection_api_result(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GovtInspectionApiResult, res.instance)
      assert_equal 'a_change', res.instance.upn_number
      refute_equal value, res.instance.upn_number
    end

    def test_update_govt_inspection_api_result_fail
      skip 'pallet_factory needed'
      id = create_govt_inspection_api_result
      attrs = interactor.send(:repo).find_hash(:govt_inspection_api_results, id).reject { |k, _| %i[id upn_number].include?(k) }
      res = interactor.update_govt_inspection_api_result(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:upn_number]
    end

    def test_delete_govt_inspection_api_result
      skip 'pallet_factory needed'
      id = create_govt_inspection_api_result
      assert_count_changed(:govt_inspection_api_results, -1) do
        res = interactor.delete_govt_inspection_api_result(id)
        assert res.success, res.message
      end
    end

    private

    def govt_inspection_api_result_attrs
      govt_inspection_sheet_id = create_govt_inspection_sheet

      {
        id: 1,
        govt_inspection_sheet_id: govt_inspection_sheet_id,
        govt_inspection_request_doc: {},
        govt_inspection_result_doc: {},
        results_requested: false,
        results_requested_at: '2010-01-01 12:00',
        results_received: false,
        results_received_at: '2010-01-01 12:00',
        upn_number: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_govt_inspection_api_result(overrides = {})
      GovtInspectionApiResult.new(govt_inspection_api_result_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GovtInspectionApiResultInteractor.new(current_user, {}, {}, {})
    end
  end
end
