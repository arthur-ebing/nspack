# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFruitActualCountsForPackInteractor < MiniTestWithHooks
    include GeneralFactory
    include FruitFactory
    include CommodityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FruitSizeRepo)
    end

    def test_fruit_actual_counts_for_pack
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_fruit_actual_counts_for_pack).returns(fake_fruit_actual_counts_for_pack)
      entity = interactor.send(:fruit_actual_counts_for_pack, 1)
      assert entity.is_a?(FruitActualCountsForPack)
    end

    def test_create_fruit_actual_counts_for_pack
      attrs = fake_fruit_actual_counts_for_pack.to_h.reject { |k, _| k == :id }
      attrs = attrs.to_h
      res = interactor.create_fruit_actual_counts_for_pack(attrs[:std_fruit_size_count_id], attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitActualCountsForPack, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_fruit_actual_counts_for_pack_fail
      attrs = fake_fruit_actual_counts_for_pack(basic_pack_code_id: nil).to_h.reject { |k, _| k == :id }
      attrs = attrs.to_h
      res = interactor.create_fruit_actual_counts_for_pack(attrs[:std_fruit_size_count_id], attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:basic_pack_code_id]
    end

    def test_update_fruit_actual_counts_for_pack
      id = create_fruit_actual_counts_for_pack
      attrs = interactor.send(:repo).find_fruit_actual_counts_for_pack(id)
      attrs = attrs.to_h
      value = attrs[:actual_count_for_pack]
      attrs[:actual_count_for_pack] = 20
      res = interactor.update_fruit_actual_counts_for_pack(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitActualCountsForPack, res.instance)
      assert_equal 20, res.instance.actual_count_for_pack
      refute_equal value, res.instance.actual_count_for_pack
    end

    def test_update_fruit_actual_counts_for_pack_fail
      id = create_fruit_actual_counts_for_pack
      attrs = interactor.send(:repo).find_fruit_actual_counts_for_pack(id)
      attrs = attrs.to_h
      attrs.delete(:basic_pack_code_id)
      value = attrs[:actual_count_for_pack]
      attrs[:actual_count_for_pack] = 20
      res = interactor.update_fruit_actual_counts_for_pack(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:basic_pack_code_id]
      after = interactor.send(:repo).find_fruit_actual_counts_for_pack(id)
      after = after.to_h
      refute_equal 20, after[:actual_count_for_pack]
      assert_equal value, after[:actual_count_for_pack]
    end

    def test_delete_fruit_actual_counts_for_pack
      id = create_fruit_actual_counts_for_pack
      assert_count_changed(:fruit_actual_counts_for_packs, -1) do
        res = interactor.delete_fruit_actual_counts_for_pack(id)
        assert res.success, res.message
      end
    end

    private

    def fruit_actual_counts_for_pack_attrs
      std_fruit_size_count_id = create_std_fruit_size_count
      basic_pack_code_id = create_basic_pack_code
      standard_pack_code_ids = create_standard_pack_code
      size_reference_ids = create_fruit_size_reference

      {
        id: 1,
        std_fruit_size_count_id: std_fruit_size_count_id,
        basic_pack_code_id: basic_pack_code_id,
        actual_count_for_pack: 1,
        standard_pack_code_ids: [standard_pack_code_ids],
        size_reference_ids: [size_reference_ids],
        std_fruit_size_count: 'ABC',
        basic_pack_code: 'ABC',
        standard_packs: 'ABC',
        size_references: 'ABC',
        active: true
      }
    end

    def fake_fruit_actual_counts_for_pack(overrides = {})
      FruitActualCountsForPack.new(fruit_actual_counts_for_pack_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= FruitSizeInteractor.new(current_user, {}, {}, {})
    end
  end
end
