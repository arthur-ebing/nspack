# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionPalletInteractor < MiniTestWithHooks
    include GovtInspectionFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::PackagingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::GovtInspectionPalletRepo)
    end

    def test_govt_inspection_pallet
      skip 'pallet_factory needed'
      FinishedGoodsApp::GovtInspectionPalletRepo.any_instance.stubs(:find_govt_inspection_pallet).returns(fake_govt_inspection_pallet)
      entity = interactor.send(:govt_inspection_pallet, 1)
      assert entity.is_a?(GovtInspectionPallet)
    end

    def test_create_govt_inspection_pallet
      skip 'pallet_factory needed'
      attrs = fake_govt_inspection_pallet.to_h.reject { |k, _| k == :id }
      res = interactor.create_govt_inspection_pallet(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GovtInspectionPallet, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_govt_inspection_pallet_fail
      skip 'pallet_factory needed'
      attrs = fake_govt_inspection_pallet(failure_remarks: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_govt_inspection_pallet(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:failure_remarks]
    end

    def test_update_govt_inspection_pallet
      skip 'pallet_factory needed'
      id = create_govt_inspection_pallet
      attrs = interactor.send(:repo).find_hash(:govt_inspection_pallets, id).reject { |k, _| k == :id }
      value = attrs[:failure_remarks]
      attrs[:failure_remarks] = 'a_change'
      res = interactor.update_govt_inspection_pallet(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(GovtInspectionPallet, res.instance)
      assert_equal 'a_change', res.instance.failure_remarks
      refute_equal value, res.instance.failure_remarks
    end

    def test_update_govt_inspection_pallet_fail
      skip 'pallet_factory needed'
      id = create_govt_inspection_pallet
      attrs = interactor.send(:repo).find_hash(:govt_inspection_pallets, id).reject { |k, _| %i[id failure_remarks].include?(k) }
      res = interactor.update_govt_inspection_pallet(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:failure_remarks]
    end

    def test_delete_govt_inspection_pallet
      skip 'pallet_factory needed'
      id = create_govt_inspection_pallet
      assert_count_changed(:govt_inspection_pallets, -1) do
        res = interactor.delete_govt_inspection_pallet(id)
        assert res.success, res.message
      end
    end

    private

    def govt_inspection_pallet_attrs
      pallet_id = create_pallet_base
      govt_inspection_sheet_id = create_govt_inspection_sheet
      failure_reason_id = create_inspection_failure_reason

      {
        id: 1,
        pallet_id: pallet_id,
        govt_inspection_sheet_id: govt_inspection_sheet_id,
        passed: false,
        inspected: false,
        inspected_at: '2010-01-01 12:00',
        failure_reason_id: failure_reason_id,
        failure_remarks: Faker::Lorem.unique.word,

        active: true
      }
    end

    def fake_govt_inspection_pallet(overrides = {})
      GovtInspectionPallet.new(govt_inspection_pallet_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GovtInspectionPalletInteractor.new(current_user, {}, {}, {})
    end
  end
end
