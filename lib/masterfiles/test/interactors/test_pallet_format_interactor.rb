# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPalletFormatInteractor < MiniTestWithHooks
    include PackagingFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PackagingRepo)
    end

    def test_pallet_format
      MasterfilesApp::PackagingRepo.any_instance.stubs(:find_pallet_format).returns(fake_pallet_format)
      entity = interactor.send(:pallet_format, 1)
      assert entity.is_a?(PalletFormat)
    end

    def test_create_pallet_format
      attrs = fake_pallet_format.to_h.reject { |k, _| k == :id }
      res = interactor.create_pallet_format(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PalletFormat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_pallet_format_fail
      attrs = fake_pallet_format(description: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_pallet_format(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:description]
    end

    def test_update_pallet_format
      id = create_pallet_format
      attrs = interactor.send(:repo).find_pallet_format(id)
      attrs = attrs.to_h
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_pallet_format(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PalletFormat, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_pallet_format_fail
      id = create_pallet_format
      attrs = interactor.send(:repo).find_pallet_format(id).to_h
      value = attrs.delete(:description)
      res = interactor.update_pallet_format(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:description]
      after = interactor.send(:repo).find_pallet_format(id).to_h
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_pallet_format
      id = create_pallet_format
      assert_count_changed(:pallet_formats, -1) do
        res = interactor.delete_pallet_format(id)
        assert res.success, res.message
      end
    end

    private

    def pallet_format_attrs
      pallet_base_id = create_pallet_base
      pallet_stack_type_id = create_pallet_stack_type

      {
        id: 1,
        description: Faker::Lorem.unique.word,
        pallet_base_id: pallet_base_id,
        pallet_stack_type_id: pallet_stack_type_id,
        pallet_base_code: 'ABC',
        stack_type_code: 'ABC',
        active: true
      }
    end

    def fake_pallet_format(overrides = {})
      PalletFormat.new(pallet_format_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PalletFormatInteractor.new(current_user, {}, {}, {})
    end
  end
end
