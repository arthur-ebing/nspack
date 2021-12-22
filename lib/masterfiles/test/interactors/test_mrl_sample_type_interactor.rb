# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMrlSampleTypeInteractor < MiniTestWithHooks
    include QualityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::QualityRepo)
    end

    def test_mrl_sample_type
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_mrl_sample_type).returns(fake_mrl_sample_type)
      entity = interactor.send(:mrl_sample_type, 1)
      assert entity.is_a?(MrlSampleType)
    end

    def test_create_mrl_sample_type
      attrs = fake_mrl_sample_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_mrl_sample_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MrlSampleType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_mrl_sample_type_fail
      attrs = fake_mrl_sample_type(sample_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_mrl_sample_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:sample_type_code]
    end

    def test_update_mrl_sample_type
      id = create_mrl_sample_type
      attrs = interactor.send(:repo).find_hash(:mrl_sample_types, id).reject { |k, _| k == :id }
      value = attrs[:sample_type_code]
      attrs[:sample_type_code] = 'a_change'
      res = interactor.update_mrl_sample_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(MrlSampleType, res.instance)
      assert_equal 'a_change', res.instance.sample_type_code
      refute_equal value, res.instance.sample_type_code
    end

    def test_update_mrl_sample_type_fail
      id = create_mrl_sample_type
      attrs = interactor.send(:repo).find_hash(:mrl_sample_types, id).reject { |k, _| %i[id sample_type_code].include?(k) }
      res = interactor.update_mrl_sample_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:sample_type_code]
    end

    def test_delete_mrl_sample_type
      id = create_mrl_sample_type(force_create: true)
      assert_count_changed(:mrl_sample_types, -1) do
        res = interactor.delete_mrl_sample_type(id)
        assert res.success, res.message
      end
    end

    private

    def mrl_sample_type_attrs
      {
        id: 1,
        sample_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_mrl_sample_type(overrides = {})
      MrlSampleType.new(mrl_sample_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= MrlSampleTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
