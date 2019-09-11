# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestRmtContainerTypeInteractor < MiniTestWithHooks
    include RmtContainerTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::RmtContainerTypeRepo)
    end

    def test_rmt_container_type
      MasterfilesApp::RmtContainerTypeRepo.any_instance.stubs(:find_rmt_container_type).returns(fake_rmt_container_type)
      entity = interactor.send(:rmt_container_type, 1)
      assert entity.is_a?(RmtContainerType)
    end

    def test_create_rmt_container_type
      attrs = fake_rmt_container_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_rmt_container_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtContainerType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_rmt_container_type_fail
      attrs = fake_rmt_container_type(container_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_rmt_container_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:container_type_code]
    end

    def test_update_rmt_container_type
      id = create_rmt_container_type
      attrs = interactor.send(:repo).find_hash(:rmt_container_types, id).reject { |k, _| k == :id }
      value = attrs[:container_type_code]
      attrs[:container_type_code] = 'a_change'
      res = interactor.update_rmt_container_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtContainerType, res.instance)
      assert_equal 'a_change', res.instance.container_type_code
      refute_equal value, res.instance.container_type_code
    end

    def test_update_rmt_container_type_fail
      id = create_rmt_container_type
      attrs = interactor.send(:repo).find_hash(:rmt_container_types, id).reject { |k, _| %i[id container_type_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_rmt_container_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:container_type_code]
      after = interactor.send(:repo).find_hash(:rmt_container_types, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_rmt_container_type
      id = create_rmt_container_type
      assert_count_changed(:rmt_container_types, -1) do
        res = interactor.delete_rmt_container_type(id)
        assert res.success, res.message
      end
    end

    private

    def rmt_container_type_attrs
      {
        id: 1,
        container_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true,
        tare_weight: 20.3,
        rmt_inner_container_type_id: 1
      }
    end

    def fake_rmt_container_type(overrides = {})
      RmtContainerType.new(rmt_container_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= RmtContainerTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
