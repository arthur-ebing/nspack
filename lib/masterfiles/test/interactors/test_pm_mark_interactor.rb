# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmMarkInteractor < MiniTestWithHooks
    include PackagingFactory
    include MarketingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::BomRepo)
    end

    def test_pm_mark
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_mark).returns(fake_pm_mark)
      entity = interactor.send(:pm_mark, 1)
      assert entity.is_a?(PmMark)
    end

    def test_create_pm_mark
      attrs = fake_pm_mark.to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_mark(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmMarkFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pm_mark_fail
      attrs = fake_pm_mark(description: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_mark(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:description]
    end

    def test_update_pm_mark
      id = create_pm_mark
      attrs = interactor.send(:repo).find_hash(:pm_marks, id).reject { |k, _| k == :id }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_pm_mark(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmMarkFlat, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_pm_mark_fail
      id = create_pm_mark
      attrs = interactor.send(:repo).find_hash(:pm_marks, id).reject { |k, _| %i[id description].include?(k) }
      res = interactor.update_pm_mark(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:description]
    end

    def test_delete_pm_mark
      id = create_pm_mark
      assert_count_changed(:pm_marks, -1) do
        res = interactor.delete_pm_mark(id)
        assert res.success, res.message
      end
    end

    private

    def pm_mark_attrs
      mark_id = create_mark

      {
        id: 1,
        mark_id: mark_id,
        packaging_marks: %w[1 2 3],
        description: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_pm_mark(overrides = {})
      PmMark.new(pm_mark_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PmMarkInteractor.new(current_user, {}, {}, {})
    end
  end
end
