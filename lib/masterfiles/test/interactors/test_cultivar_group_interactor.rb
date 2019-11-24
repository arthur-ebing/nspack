# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCultivarGroupInteractor < MiniTestWithHooks
    include CommodityFactory
    include CultivarFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::CultivarRepo)
    end

    def test_cultivar_group
      MasterfilesApp::CultivarRepo.any_instance.stubs(:find_cultivar_group_flat).returns(fake_cultivar_group)
      entity = interactor.send(:cultivar_group, 1)
      assert entity.is_a?(CultivarGroupFlat)
    end

    def test_create_cultivar_group
      attrs = fake_cultivar_group.to_h.reject { |k, _| k == :id }
      res = interactor.create_cultivar_group(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CultivarGroupFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_cultivar_group_fail
      attrs = fake_cultivar_group(cultivar_group_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_cultivar_group(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:cultivar_group_code]
    end

    def test_update_cultivar_group
      id = create_cultivar_group
      attrs = interactor.send(:repo).find_hash(:cultivar_groups, id).reject { |k, _| k == :id }
      value = attrs[:cultivar_group_code]
      attrs[:cultivar_group_code] = 'a_change'
      res = interactor.update_cultivar_group(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CultivarGroupFlat, res.instance)
      assert_equal 'a_change', res.instance.cultivar_group_code
      refute_equal value, res.instance.cultivar_group_code
    end

    def test_update_cultivar_group_fail
      id = create_cultivar_group
      attrs = interactor.send(:repo).find_hash(:cultivar_groups, id).reject { |k, _| %i[id cultivar_group_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_cultivar_group(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:cultivar_group_code]
      after = interactor.send(:repo).find_hash(:cultivar_groups, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_cultivar_group
      id = create_cultivar_group
      assert_count_changed(:cultivar_groups, -1) do
        res = interactor.delete_cultivar_group(id)
        assert res.success, res.message
      end
    end

    private

    def cultivar_group_attrs
      commodity_id = create_commodity
      {
        id: 1,
        commodity_id: commodity_id,
        commodity_code: 'dummy',
        cultivar_group_code: Faker::Lorem.unique.word,
        description: 'ABC',
        cultivar_ids: [1],
        active: true
      }
    end

    def fake_cultivar_group(overrides = {})
      CultivarGroupFlat.new(cultivar_group_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= CultivarInteractor.new(current_user, {}, {}, {})
    end
  end
end
