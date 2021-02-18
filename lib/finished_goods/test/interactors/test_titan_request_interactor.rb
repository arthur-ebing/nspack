# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestTitanRequestInteractor < MiniTestWithHooks
    include FinishedGoodsApp::TitanFactory
    include FinishedGoodsApp::LoadFactory
    include FinishedGoodsApp::VoyageFactory
    include FinishedGoodsApp::VoyagePortFactory
    include FinishedGoodsApp::GovtInspectionFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::VesselFactory
    include MasterfilesApp::PortFactory
    include MasterfilesApp::PortTypeFactory
    include MasterfilesApp::TargetMarketFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::TitanRepo)
    end

    def test_titan_request
      FinishedGoodsApp::TitanRepo.any_instance.stubs(:find_titan_request).returns(fake_titan_request)
      entity = interactor.send(:titan_request, 1)
      assert entity.is_a?(TitanRequest)
    end

    def test_delete_titan_request
      id = create_titan_request
      assert_count_changed(:titan_requests, -1) do
        res = interactor.delete_titan_request(id)
        assert res.success, res.message
      end
    end

    private

    def titan_request_attrs
      load_id = create_load
      govt_inspection_sheet_id = create_govt_inspection_sheet

      {
        id: 1,
        load_id: load_id,
        govt_inspection_sheet_id: govt_inspection_sheet_id,
        request_doc: { test: 'test' },
        result_doc: { test: 'test' },
        request_array: [],
        result_array: [],
        request_type: Faker::Lorem.unique.word,
        inspection_message_id: 1,
        transaction_id: 1,
        request_id: 1,
        created_at: Time.now
      }
    end

    def fake_titan_request(overrides = {})
      TitanRequest.new(titan_request_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= TitanRequestInteractor.new(current_user, {}, {}, {})
    end
  end
end
