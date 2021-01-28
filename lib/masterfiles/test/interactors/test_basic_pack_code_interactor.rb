# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestBasicPackCodeInteractor < MiniTestWithHooks
    include FruitFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FruitSizeRepo)
    end

    def test_basic_pack_code
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_basic_pack_code).returns(fake_basic_pack_code)
      entity = interactor.send(:basic_pack_code, 1)
      assert entity.is_a?(BasicPackCode)
    end

    def test_create_basic_pack_code
      attrs = fake_basic_pack_code.to_h.reject { |k, _| k == :id }
      res = interactor.create_basic_pack_code(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(BasicPackCode, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_basic_pack_code_fail
      attrs = fake_basic_pack_code(basic_pack_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_basic_pack_code(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:basic_pack_code]
    end

    def test_update_basic_pack_code
      id = create_basic_pack_code
      attrs = interactor.send(:repo).find_hash(:basic_pack_codes, id).reject { |k, _| k == :id }
      value = attrs[:basic_pack_code]
      attrs[:basic_pack_code] = 'a_change'
      res = interactor.update_basic_pack_code(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(BasicPackCode, res.instance)
      assert_equal 'a_change', res.instance.basic_pack_code
      refute_equal value, res.instance.basic_pack_code
    end

    def test_update_basic_pack_code_fail
      id = create_basic_pack_code
      attrs = interactor.send(:repo).find_hash(:basic_pack_codes, id).reject { |k, _| %i[id basic_pack_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_basic_pack_code(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:basic_pack_code]
      after = interactor.send(:repo).find_hash(:basic_pack_codes, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_basic_pack_code
      id = create_basic_pack_code
      assert_count_changed(:basic_pack_codes, -1) do
        res = interactor.delete_basic_pack_code(id)
        assert res.success, res.message
      end
    end

    private

    def basic_pack_code_attrs
      {
        id: 1,
        basic_pack_code: Faker::Lorem.unique.word,
        description: 'ABC',
        length_mm: 1,
        width_mm: 1,
        height_mm: 1,
        active: true,
        footprint_code: 'ABC'
      }
    end

    def fake_basic_pack_code(overrides = {})
      BasicPackCode.new(basic_pack_code_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= BasicPackCodeInteractor.new(current_user, {}, {}, {})
    end
  end
end
