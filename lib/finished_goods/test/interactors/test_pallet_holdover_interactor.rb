# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestPalletHoldoverInteractor < MiniTestWithHooks
    include PalletHoldoverFactory

    include MesscadaApp::PalletFactory
    include MasterfilesApp::PackagingFactory
    include ProductionApp::ResourceFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::FruitFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::PalletHoldoverRepo)
    end

    def test_pallet_holdover
      FinishedGoodsApp::PalletHoldoverRepo.any_instance.stubs(:find_pallet_holdover).returns(fake_pallet_holdover)
      entity = interactor.send(:pallet_holdover, 1)
      assert entity.is_a?(PalletHoldover)
    end

    def test_create_pallet_holdover
      attrs = fake_pallet_holdover.to_h.reject { |k, _| k == :id }
      res = interactor.create_pallet_holdover(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PalletHoldover, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pallet_holdover_fail
      attrs = fake_pallet_holdover(holdover_quantity: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pallet_holdover(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:holdover_quantity]
    end

    def test_update_pallet_holdover
      id = create_pallet_holdover
      attrs = interactor.send(:repo).find_hash(:pallet_holdovers, id).reject { |k, _| k == :id }
      value = attrs[:buildup_remarks]
      attrs[:buildup_remarks] = 'a_change'
      res = interactor.update_pallet_holdover(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PalletHoldover, res.instance)
      assert_equal 'a_change', res.instance.buildup_remarks
      refute_equal value, res.instance.buildup_remarks
    end

    def test_update_pallet_holdover_fail
      id = create_pallet_holdover
      attrs = interactor.send(:repo).find_hash(:pallet_holdovers, id).reject { |k, _| %i[id buildup_remarks].include?(k) }
      res = interactor.update_pallet_holdover(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:buildup_remarks]
    end

    def test_delete_pallet_holdover
      id = create_pallet_holdover(force_create: true)
      assert_count_changed(:pallet_holdovers, -1) do
        res = interactor.delete_pallet_holdover(id)
        assert res.success, res.message
      end
    end

    private

    def pallet_holdover_attrs
      pallet_id = create_pallet

      {
        id: 1,
        pallet_id: pallet_id,
        pallet_number: '1234567',
        holdover_quantity: 1,
        buildup_remarks: Faker::Lorem.unique.word,
        completed: false
      }
    end

    def fake_pallet_holdover(overrides = {})
      PalletHoldover.new(pallet_holdover_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PalletHoldoverInteractor.new(current_user, {}, {}, {})
    end
  end
end
