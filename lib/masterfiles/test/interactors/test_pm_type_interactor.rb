# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmTypeInteractor < MiniTestWithHooks
    include PackagingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::BomsRepo)
    end

    def test_pm_type
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_type).returns(fake_pm_type)
      entity = interactor.send(:pm_type, 1)
      assert entity.is_a?(PmType)
    end

    def test_create_pm_type
      attrs = fake_pm_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pm_type_fail
      attrs = fake_pm_type(pm_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:pm_type_code]
    end

    def test_update_pm_type
      id = create_pm_type
      attrs = interactor.send(:repo).find_hash(:pm_types, id).reject { |k, _| k == :id }
      value = attrs[:pm_type_code]
      attrs[:pm_type_code] = 'a_change'
      res = interactor.update_pm_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmType, res.instance)
      assert_equal 'a_change', res.instance.pm_type_code
      refute_equal value, res.instance.pm_type_code
    end

    def test_update_pm_type_fail
      id = create_pm_type
      attrs = interactor.send(:repo).find_hash(:pm_types, id).reject { |k, _| %i[id pm_type_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_pm_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:pm_type_code]
      after = interactor.send(:repo).find_hash(:pm_types, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_pm_type
      id = create_pm_type
      assert_count_changed(:pm_types, -1) do
        res = interactor.delete_pm_type(id)
        assert res.success, res.message
      end
    end

    private

    def pm_type_attrs
      pm_composition_level_id = create_pm_composition_level

      {
        id: 1,
        pm_composition_level_id: pm_composition_level_id,
        pm_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_pm_type(overrides = {})
      PmType.new(pm_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PmTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
