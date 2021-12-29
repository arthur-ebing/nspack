# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestLaboratoryInteractor < MiniTestWithHooks
    include QualityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::QualityRepo)
    end

    def test_laboratory
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_laboratory).returns(fake_laboratory)
      entity = interactor.send(:laboratory, 1)
      assert entity.is_a?(Laboratory)
    end

    def test_create_laboratory
      attrs = fake_laboratory.to_h.reject { |k, _| k == :id }
      res = interactor.create_laboratory(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Laboratory, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_laboratory_fail
      attrs = fake_laboratory(lab_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_laboratory(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:lab_code]
    end

    def test_update_laboratory
      id = create_laboratory
      attrs = interactor.send(:repo).find_hash(:laboratories, id).reject { |k, _| k == :id }
      value = attrs[:lab_code]
      attrs[:lab_code] = 'a_change'
      res = interactor.update_laboratory(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Laboratory, res.instance)
      assert_equal 'a_change', res.instance.lab_code
      refute_equal value, res.instance.lab_code
    end

    def test_update_laboratory_fail
      id = create_laboratory
      attrs = interactor.send(:repo).find_hash(:laboratories, id).reject { |k, _| %i[id lab_code].include?(k) }
      res = interactor.update_laboratory(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:lab_code]
    end

    def test_delete_laboratory
      id = create_laboratory(force_create: true)
      assert_count_changed(:laboratories, -1) do
        res = interactor.delete_laboratory(id)
        assert res.success, res.message
      end
    end

    private

    def laboratory_attrs
      {
        id: 1,
        lab_code: Faker::Lorem.unique.word,
        lab_name: 'ABC',
        description: 'ABC',
        active: true
      }
    end

    def fake_laboratory(overrides = {})
      Laboratory.new(laboratory_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= LaboratoryInteractor.new(current_user, {}, {}, {})
    end
  end
end
