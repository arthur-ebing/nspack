# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestStandardPackCodeInteractor < MiniTestWithHooks
    include GeneralFactory
    include FruitFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FruitSizeRepo)
    end

    def test_standard_pack_code
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_standard_pack_code_flat).returns(fake_standard_pack_code)
      entity = interactor.send(:standard_pack_code, 1)
      assert entity.is_a?(StandardPackCodeFlat)
    end

    def test_create_standard_pack_code
      attrs = fake_standard_pack_code.to_h.reject { |k, _| k == :id }
      res = interactor.create_standard_pack_code(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(StandardPackCodeFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_standard_pack_code_fail
      attrs = fake_standard_pack_code(standard_pack_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_standard_pack_code(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:standard_pack_code]
    end

    def test_update_standard_pack_code
      id = create_standard_pack_code
      attrs = interactor.send(:repo).find_hash(:standard_pack_codes, id).reject { |k, _| k == :id }
      value = attrs[:standard_pack_code]
      attrs[:standard_pack_code] = 'a_change'
      res = interactor.update_standard_pack_code(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(StandardPackCodeFlat, res.instance)
      assert_equal 'a_change', res.instance.standard_pack_code
      refute_equal value, res.instance.standard_pack_code
    end

    def test_update_standard_pack_code_fail
      id = create_standard_pack_code
      attrs = interactor.send(:repo).find_hash(:standard_pack_codes, id)
      attrs.delete(:standard_pack_code)
      value = attrs[:description]
      attrs[:id] = 'a change'
      res = interactor.update_standard_pack_code(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:standard_pack_code]
      after = interactor.send(:repo).find_hash(:standard_pack_codes, id)
      refute_equal 'a change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_standard_pack_code
      id = create_standard_pack_code
      assert_count_changed(:standard_pack_codes, -1) do
        res = interactor.delete_standard_pack_code(id)
        assert res.success, res.message
      end
    end

    private

    def standard_pack_code_attrs
      basic_pack_code_id = create_basic_pack_code
      {
        id: 1,
        standard_pack_code: Faker::Lorem.unique.word,
        description: 'ABC',
        std_pack_label_code: 'ABC',
        active: true,
        material_mass: 1.0,
        plant_resource_button_indicator: 'ABC',
        basic_pack_code_id: basic_pack_code_id,
        basic_pack_code: 'ABC',
        use_size_ref_for_edi: false,
        palletizer_incentive_rate: 1.0,
        bin: false,
        rmt_container_type_id: nil,
        container_type: nil,
        rmt_container_material_type_id: nil,
        material_type: nil
      }
    end

    def fake_standard_pack_code(overrides = {})
      StandardPackCodeFlat.new(standard_pack_code_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= StandardPackCodeInteractor.new(current_user, {}, {}, {})
    end
  end
end
