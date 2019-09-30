# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPortTypeInteractor < MiniTestWithHooks
    include PortTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PortTypeRepo)
    end

    def test_port_type
      MasterfilesApp::PortTypeRepo.any_instance.stubs(:find_port_type).returns(fake_port_type)
      entity = interactor.send(:port_type, 1)
      assert entity.is_a?(PortType)
    end

    def test_create_port_type
      attrs = fake_port_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_port_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PortType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_port_type_fail
      attrs = fake_port_type(port_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_port_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:port_type_code]
    end

    def test_update_port_type
      id = create_port_type
      attrs = interactor.send(:repo).find_hash(:port_types, id).reject { |k, _| k == :id }
      value = attrs[:port_type_code]
      attrs[:port_type_code] = 'a_change'
      res = interactor.update_port_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PortType, res.instance)
      assert_equal 'a_change', res.instance.port_type_code
      refute_equal value, res.instance.port_type_code
    end

    def test_update_port_type_fail
      id = create_port_type
      attrs = interactor.send(:repo).find_hash(:port_types, id).reject { |k, _| %i[id port_type_code].include?(k) }
      res = interactor.update_port_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:port_type_code]
    end

    def test_delete_port_type
      id = create_port_type
      assert_count_changed(:port_types, -1) do
        res = interactor.delete_port_type(id)
        assert res.success, res.message
      end
    end

    private

    def port_type_attrs
      {
        id: 1,
        port_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_port_type(overrides = {})
      PortType.new(port_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PortTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
