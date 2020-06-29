# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInventoryCodeInteractor < MiniTestWithHooks
    include FruitFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FruitRepo)
    end

    def test_inventory_code
      MasterfilesApp::FruitRepo.any_instance.stubs(:find_inventory_code).returns(fake_inventory_code)
      entity = interactor.send(:inventory_code, 1)
      assert entity.is_a?(InventoryCode)
    end

    def test_create_inventory_code
      attrs = fake_inventory_code.to_h.reject { |k, _| k == :id }
      res = interactor.create_inventory_code(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InventoryCode, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_inventory_code_fail
      attrs = fake_inventory_code(inventory_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_inventory_code(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:inventory_code]
    end

    def test_update_inventory_code
      id = create_inventory_code
      attrs = interactor.send(:repo).find_hash(:inventory_codes, id).reject { |k, _| k == :id }
      value = attrs[:inventory_code]
      attrs[:inventory_code] = 'a_change'
      res = interactor.update_inventory_code(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(InventoryCode, res.instance)
      assert_equal 'a_change', res.instance.inventory_code
      refute_equal value, res.instance.inventory_code
    end

    def test_update_inventory_code_fail
      id = create_inventory_code
      attrs = interactor.send(:repo).find_hash(:inventory_codes, id).reject { |k, _| %i[id inventory_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_inventory_code(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:inventory_code]
      after = interactor.send(:repo).find_hash(:inventory_codes, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_inventory_code
      id = create_inventory_code
      assert_count_changed(:inventory_codes, -1) do
        res = interactor.delete_inventory_code(id)
        assert res.success, res.message
      end
    end

    private

    def inventory_code_attrs
      {
        id: 1,
        inventory_code: Faker::Lorem.unique.word,
        description: 'ABC',
        edi_out_inventory_code: 'ABC',
        fruit_item_incentive_rate: 1.0,
        active: true
      }
    end

    def fake_inventory_code(overrides = {})
      InventoryCode.new(inventory_code_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= InventoryCodeInteractor.new(current_user, {}, {}, {})
    end
  end
end
