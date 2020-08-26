# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionSheetInteractor < MiniTestWithHooks
    include GovtInspectionFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::TargetMarketFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::GovtInspectionRepo)
    end

    def test_govt_inspection_sheet
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(fake_govt_inspection_sheet)
      entity = interactor.send(:find_govt_inspection_sheet, 1)
      assert entity.is_a?(GovtInspectionSheet)
    end

    def test_create_govt_inspection_sheet
      attrs = fake_govt_inspection_sheet.to_h.reject { |k, _| k == :id }
      res = interactor.create_govt_inspection_sheet(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GovtInspectionSheet, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_govt_inspection_sheet_fail
      attrs = fake_govt_inspection_sheet(booking_reference: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_govt_inspection_sheet(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:booking_reference]
    end

    def test_update_govt_inspection_sheet
      id = create_govt_inspection_sheet
      attrs = interactor.send(:repo).find_hash(:govt_inspection_sheets, id).reject { |k, _| k == :id }
      value = attrs[:booking_reference]
      attrs[:booking_reference] = 'a_change'
      res = interactor.update_govt_inspection_sheet(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GovtInspectionSheet, res.instance)
      assert_equal 'a_change', res.instance.booking_reference
      refute_equal value, res.instance.booking_reference
    end

    def test_update_govt_inspection_sheet_fail
      id = create_govt_inspection_sheet
      attrs = interactor.send(:repo).find_hash(:govt_inspection_sheets, id).reject { |k, _| %i[id booking_reference].include?(k) }
      res = interactor.update_govt_inspection_sheet(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:booking_reference]
    end

    def test_delete_govt_inspection_sheet
      id = create_govt_inspection_sheet
      assert_count_changed(:govt_inspection_sheets, -1) do
        res = interactor.delete_govt_inspection_sheet(id)
        assert res.success, res.message
      end
    end

    private

    def govt_inspection_sheet_attrs
      inspector_id = create_inspector
      inspection_billing_party_role_id = create_party_role('O', AppConst::ROLE_INSPECTION_BILLING)
      exporter_party_role_id = create_party_role('O', AppConst::ROLE_EXPORTER)
      target_market_group_id = create_target_market_group
      destination_region_id = create_destination_region
      {
        id: 1,
        inspector_id: inspector_id,
        inspector: Faker::Lorem.unique.word,
        inspection_billing_party_role_id: inspection_billing_party_role_id,
        inspection_billing: Faker::Lorem.unique.word,
        exporter_party_role_id: exporter_party_role_id,
        exporter: Faker::Lorem.unique.word,
        booking_reference: Faker::Lorem.unique.word,
        results_captured: false,
        results_captured_at: '2010-01-01 12:00',
        api_results_received: false,
        allocated: false,
        passed_pallets: false,
        failed_pallets: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        inspected: false,
        inspection_point: 'ABC',
        awaiting_inspection_results: false,
        packed_tm_group_id: target_market_group_id,
        packed_tm_group: Faker::Lorem.unique.word,
        destination_region_id: destination_region_id,
        destination_region: Faker::Lorem.unique.word,
        govt_inspection_api_result_id: nil,
        reinspection: false,
        created_by: 'ABC',
        consignment_note_number: '00000001',
        cancelled: false,
        cancelled_at: nil,
        tripsheet_created: false,
        tripsheet_created_at: '2010-01-01 12:00',
        tripsheet_loaded: false,
        tripsheet_loaded_at: '2010-01-01 12:00',
        tripsheet_offloaded: false,
        as_edi_location: false,
        active: true
      }
    end

    def fake_govt_inspection_sheet(overrides = {})
      GovtInspectionSheet.new(govt_inspection_sheet_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GovtInspectionSheetInteractor.new(current_user, {}, {}, {})
    end
  end
end
