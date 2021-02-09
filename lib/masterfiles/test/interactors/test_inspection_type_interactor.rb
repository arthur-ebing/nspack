# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectionTypeInteractor < MiniTestWithHooks
    include InspectionFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::QualityRepo)
    end

    def test_inspection_type
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_inspection_type).returns(fake_inspection_type)
      entity = interactor.send(:inspection_type, 1)
      assert entity.is_a?(InspectionType)
    end

    def test_create_inspection_type
      attrs = fake_inspection_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_inspection_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InspectionType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_inspection_type_fail
      attrs = fake_inspection_type(inspection_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_inspection_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:inspection_type_code]
    end

    def test_update_inspection_type
      id = create_inspection_type
      attrs = interactor.send(:repo).find_hash(:inspection_types, id).reject { |k, _| k == :id }
      value = attrs[:inspection_type_code]
      attrs[:inspection_type_code] = 'a_change'
      res = interactor.update_inspection_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InspectionType, res.instance)
      assert_equal 'a_change', res.instance.inspection_type_code
      refute_equal value, res.instance.inspection_type_code
    end

    def test_update_inspection_type_fail
      id = create_inspection_type
      attrs = interactor.send(:repo).find_hash(:inspection_types, id).reject { |k, _| %i[id inspection_type_code].include?(k) }
      res = interactor.update_inspection_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:inspection_type_code]
    end

    def test_delete_inspection_type
      id = create_inspection_type
      assert_count_changed(:inspection_types, -1) do
        res = interactor.delete_inspection_type(id)
        assert res.success, res.message
      end
    end

    private

    def inspection_type_attrs
      inspection_failure_type_id = create_inspection_failure_type

      {
        id: 1,
        inspection_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        inspection_failure_type_id: inspection_failure_type_id,
        failure_type_code: 'ABC',
        applies_to_all_tm_groups: false,
        applicable_tm_group_ids: [1, 2, 3],
        applicable_tm_groups: %w[A B C],
        applies_to_all_cultivars: false,
        applicable_cultivar_ids: [1, 2, 3],
        applicable_cultivars: %w[A B C],
        applies_to_all_orchards: false,
        applicable_orchard_ids: [1, 2, 3],
        applicable_orchards: %w[A B C],
        applies_to_all_grades: false,
        applicable_grade_ids: [1, 2, 3],
        applicable_grades: %w[A B C],
        active: true
      }
    end

    def fake_inspection_type(overrides = {})
      InspectionType.new(inspection_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= InspectionTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
