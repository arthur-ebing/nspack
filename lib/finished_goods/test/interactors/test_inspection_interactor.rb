# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestInspectionInteractor < MiniTestWithHooks
    include InspectionFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::InspectionRepo)
    end

    def test_inspection
      skip('Need PalletFactory')
      FinishedGoodsApp::InspectionRepo.any_instance.stubs(:find_inspection).returns(fake_inspection)
      entity = interactor.send(:inspection, 1)
      assert entity.is_a?(Inspection)
    end

    def test_create_inspection
      skip('Need PalletFactory')
      attrs = fake_inspection.to_h.reject { |k, _| k == :id }
      res = interactor.create_inspection(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Inspection, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_inspection_fail
      skip('Need PalletFactory')
      attrs = fake_inspection(remarks: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_inspection(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:remarks]
    end

    def test_update_inspection
      skip('Need PalletFactory')
      id = create_inspection
      attrs = interactor.send(:repo).find_hash(:inspections, id).reject { |k, _| k == :id }
      value = attrs[:remarks]
      attrs[:remarks] = 'a_change'
      res = interactor.update_inspection(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Inspection, res.instance)
      assert_equal 'a_change', res.instance.remarks
      refute_equal value, res.instance.remarks
    end

    def test_update_inspection_fail
      skip('Need PalletFactory')
      id = create_inspection
      attrs = interactor.send(:repo).find_hash(:inspections, id).reject { |k, _| %i[id remarks].include?(k) }
      res = interactor.update_inspection(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:remarks]
    end

    def test_delete_inspection
      skip('Need PalletFactory')
      id = create_inspection
      assert_count_changed(:inspections, -1) do
        res = interactor.delete_inspection(id)
        assert res.success, res.message
      end
    end

    private

    def inspection_attrs
      inspection_type_id = create_inspection_type
      pallet_id = create_pallet
      inspector_id = create_inspector

      {
        id: 1,
        inspection_type_id: inspection_type_id,
        pallet_id: pallet_id,
        inspector_id: inspector_id,
        inspection_failure_reason_ids: [1, 2, 3],
        passed: false,
        remarks: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_inspection(overrides = {})
      Inspection.new(inspection_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= InspectionInteractor.new(current_user, {}, {}, {})
    end
  end
end
