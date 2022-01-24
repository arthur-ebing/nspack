# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQaStandardTypeInteractor < MiniTestWithHooks
    include QaStandardTypeFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::QaStandardTypeRepo)
    end

    def test_qa_standard_type
      MasterfilesApp::QaStandardTypeRepo.any_instance.stubs(:find_qa_standard_type).returns(fake_qa_standard_type)
      entity = interactor.send(:qa_standard_type, 1)
      assert entity.is_a?(QaStandardType)
    end

    def test_create_qa_standard_type
      attrs = fake_qa_standard_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_qa_standard_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QaStandardType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_qa_standard_type_fail
      attrs = fake_qa_standard_type(qa_standard_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_qa_standard_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:qa_standard_type_code]
    end

    def test_update_qa_standard_type
      id = create_qa_standard_type
      attrs = interactor.send(:repo).find_hash(:qa_standard_types, id).reject { |k, _| k == :id }
      value = attrs[:qa_standard_type_code]
      attrs[:qa_standard_type_code] = 'a_change'
      res = interactor.update_qa_standard_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QaStandardType, res.instance)
      assert_equal 'a_change', res.instance.qa_standard_type_code
      refute_equal value, res.instance.qa_standard_type_code
    end

    def test_update_qa_standard_type_fail
      id = create_qa_standard_type
      attrs = interactor.send(:repo).find_hash(:qa_standard_types, id).reject { |k, _| %i[id qa_standard_type_code].include?(k) }
      res = interactor.update_qa_standard_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:qa_standard_type_code]
    end

    def test_delete_qa_standard_type
      id = create_qa_standard_type(force_create: true)
      assert_count_changed(:qa_standard_types, -1) do
        res = interactor.delete_qa_standard_type(id)
        assert res.success, res.message
      end
    end

    private

    def qa_standard_type_attrs
      {
        id: 1,
        qa_standard_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_qa_standard_type(overrides = {})
      QaStandardType.new(qa_standard_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= QaStandardTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
