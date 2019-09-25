# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestUomInteractor < MiniTestWithHooks
    include GeneralFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::GeneralRepo)
    end

    def test_uom
      MasterfilesApp::GeneralRepo.any_instance.stubs(:find_uom).returns(fake_uom)
      entity = interactor.send(:uom, 1)
      assert entity.is_a?(Uom)
    end

    def test_create_uom
      attrs = fake_uom.to_h.reject { |k, _| k == :id }
      res = interactor.create_uom(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Uom, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_uom_fail
      attrs = fake_uom(uom_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_uom(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:uom_code]
    end

    def test_update_uom
      id = create_uom
      attrs = interactor.send(:repo).find_hash(:uoms, id).reject { |k, _| k == :id }
      value = attrs[:uom_code]
      attrs[:uom_code] = 'a_change'
      res = interactor.update_uom(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Uom, res.instance)
      assert_equal 'a_change', res.instance.uom_code
      refute_equal value, res.instance.uom_code
    end

    def test_update_uom_fail
      id = create_uom
      attrs = interactor.send(:repo).find_hash(:uoms, id).reject { |k, _| %i[id uom_code].include?(k) }
      res = interactor.update_uom(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:uom_code]
    end

    def test_delete_uom
      id = create_uom
      assert_count_changed(:uoms, -1) do
        res = interactor.delete_uom(id)
        assert res.success, res.message
      end
    end

    private

    def uom_attrs
      uom_type_id = create_uom_type

      {
        id: 1,
        uom_type_id: uom_type_id,
        uom_code: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_uom(overrides = {})
      Uom.new(uom_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= UomInteractor.new(current_user, {}, {}, {})
    end
  end
end
