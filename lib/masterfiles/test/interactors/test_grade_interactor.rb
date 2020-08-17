# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestGradeInteractor < MiniTestWithHooks
    include FruitFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FruitRepo)
    end

    def test_grade
      MasterfilesApp::FruitRepo.any_instance.stubs(:find_grade).returns(fake_grade)
      entity = interactor.send(:grade, 1)
      assert entity.is_a?(Grade)
    end

    def test_create_grade
      attrs = fake_grade.to_h.reject { |k, _| k == :id }
      res = interactor.create_grade(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Grade, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_grade_fail
      attrs = fake_grade(grade_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_grade(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:grade_code]
    end

    def test_update_grade
      id = create_grade
      attrs = interactor.send(:repo).find_hash(:grades, id).reject { |k, _| k == :id }
      value = attrs[:grade_code]
      attrs[:grade_code] = 'a_change'
      res = interactor.update_grade(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Grade, res.instance)
      assert_equal 'a_change', res.instance.grade_code
      refute_equal value, res.instance.grade_code
    end

    def test_update_grade_fail
      id = create_grade
      attrs = interactor.send(:repo).find_hash(:grades, id).reject { |k, _| %i[id grade_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_grade(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:grade_code]
      after = interactor.send(:repo).find_hash(:grades, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_grade
      id = create_grade
      assert_count_changed(:grades, -1) do
        res = interactor.delete_grade(id)
        assert res.success, res.message
      end
    end

    private

    def grade_attrs
      {
        id: 1,
        grade_code: Faker::Lorem.unique.word,
        description: 'ABC',
        rmt_grade: false,
        active: true
      }
    end

    def fake_grade(overrides = {})
      Grade.new(grade_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= GradeInteractor.new(current_user, {}, {}, {})
    end
  end
end
