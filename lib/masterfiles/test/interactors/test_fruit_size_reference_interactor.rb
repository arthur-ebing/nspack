# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFruitSizeReferenceInteractor < MiniTestWithHooks
    include FruitFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FruitSizeRepo)
    end

    def test_fruit_size_reference
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_fruit_size_reference).returns(fake_fruit_size_reference)
      entity = interactor.send(:fruit_size_reference, 1)
      assert entity.is_a?(FruitSizeReference)
    end

    def test_create_fruit_size_reference
      attrs = fake_fruit_size_reference.to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_size_reference(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitSizeReference, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_fruit_size_reference_fail
      attrs = fake_fruit_size_reference(size_reference: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_size_reference(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:size_reference]
    end

    def test_update_fruit_size_reference
      id = create_fruit_size_reference
      attrs = interactor.send(:repo).find_hash(:fruit_size_references, id).reject { |k, _| k == :id }
      value = attrs[:size_reference]
      attrs[:size_reference] = 'a_change'
      res = interactor.update_fruit_size_reference(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitSizeReference, res.instance)
      assert_equal 'a_change', res.instance.size_reference
      refute_equal value, res.instance.size_reference
    end

    def test_update_fruit_size_reference_fail
      id = create_fruit_size_reference
      attrs = interactor.send(:repo).find_hash(:fruit_size_references, id)
      value = attrs[:id]
      attrs.delete(:size_reference)
      attrs[:id] = 222
      res = interactor.update_fruit_size_reference(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:size_reference]
      after = interactor.send(:repo).find_hash(:fruit_size_references, id)
      refute_equal 222, after[:id]
      assert_equal value, after[:id]
    end

    def test_delete_fruit_size_reference
      id = create_fruit_size_reference
      assert_count_changed(:fruit_size_references, -1) do
        res = interactor.delete_fruit_size_reference(id)
        assert res.success, res.message
      end
    end

    private

    def fruit_size_reference_attrs
      {
        id: 1,
        size_reference: Faker::Lorem.unique.word,
        edi_out_code: 'ABC',
        active: true
      }
    end

    def fake_fruit_size_reference(overrides = {})
      FruitSizeReference.new(fruit_size_reference_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= FruitSizeReferenceInteractor.new(current_user, {}, {}, {})
    end
  end
end
