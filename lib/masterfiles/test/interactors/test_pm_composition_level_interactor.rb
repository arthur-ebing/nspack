# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmCompositionLevelInteractor < MiniTestWithHooks
    include PackagingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::BomRepo)
    end

    def test_pm_composition_level
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_composition_level).returns(fake_pm_composition_level)
      entity = interactor.send(:pm_composition_level, 1)
      assert entity.is_a?(PmCompositionLevel)
    end

    def test_create_pm_composition_level
      attrs = fake_pm_composition_level.to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_composition_level(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmCompositionLevel, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pm_composition_level_fail
      attrs = fake_pm_composition_level(description: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_composition_level(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:description]
    end

    def test_update_pm_composition_level
      id = create_pm_composition_level
      attrs = interactor.send(:repo).find_hash(:pm_composition_levels, id).reject { |k, _| k == :id }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_pm_composition_level(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmCompositionLevel, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_pm_composition_level_fail
      id = create_pm_composition_level
      attrs = interactor.send(:repo).find_hash(:pm_composition_levels, id).reject { |k, _| %i[id description].include?(k) }
      res = interactor.update_pm_composition_level(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:description]
    end

    def test_delete_pm_composition_level
      id = create_pm_composition_level
      assert_count_changed(:pm_composition_levels, -1) do
        res = interactor.delete_pm_composition_level(id)
        assert res.success, res.message
      end
    end

    private

    def pm_composition_level_attrs
      {
        id: 1,
        composition_level: 1,
        description: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_pm_composition_level(overrides = {})
      PmCompositionLevel.new(pm_composition_level_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PmCompositionLevelInteractor.new(current_user, {}, {}, {})
    end
  end
end
