# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmSubtypeInteractor < MiniTestWithHooks
    include PackagingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::BomRepo)
    end

    def test_pm_subtype
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_subtype).returns(fake_pm_subtype)
      entity = interactor.send(:pm_subtype, 1)
      assert entity.is_a?(PmSubtype)
    end

    def test_create_pm_subtype
      attrs = fake_pm_subtype.to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_subtype(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmSubtype, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pm_subtype_fail
      attrs = fake_pm_subtype(subtype_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pm_subtype(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:subtype_code]
    end

    def test_update_pm_subtype
      id = create_pm_subtype
      attrs = interactor.send(:repo).find_pm_subtype(id)
      attrs = attrs.to_h
      value = attrs[:subtype_code]
      attrs[:subtype_code] = 'a_change'
      res = interactor.update_pm_subtype(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PmSubtype, res.instance)
      assert_equal 'a_change', res.instance.subtype_code
      refute_equal value, res.instance.subtype_code
    end

    def test_update_pm_subtype_fail
      id = create_pm_subtype
      attrs = interactor.send(:repo).find_pm_subtype(id)
      attrs = attrs.to_h
      attrs.delete(:subtype_code)
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_pm_subtype(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:subtype_code]
      after = interactor.send(:repo).find_pm_subtype(id)
      after = after.to_h
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_pm_subtype
      id = create_pm_subtype
      assert_count_changed(:pm_subtypes, -1) do
        res = interactor.delete_pm_subtype(id)
        assert res.success, res.message
      end
    end

    private

    def pm_subtype_attrs
      pm_type_id = create_pm_type

      {
        id: 1,
        pm_type_id: pm_type_id,
        subtype_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true,
        pm_type_code: 'ABC',
        short_code: 'ABC',
        composition_level: 1,
        composition_level_description: 'ABC',
        minimum_composition_level: true,
        fruit_composition_level: false
      }
    end

    def fake_pm_subtype(overrides = {})
      PmSubtype.new(pm_subtype_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PmSubtypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
