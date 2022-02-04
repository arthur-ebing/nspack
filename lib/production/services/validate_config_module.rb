# frozen_string_literal: true

module ProductionApp
  class ValidateConfigModule < BaseService
    attr_reader :id, :repo, :peripheral_ids

    def initialize(id, peripheral_ids)
      @id = id
      @peripheral_ids = peripheral_ids
      @repo = ResourceRepo.new
    end

    def call
      @sys_mod = repo.find_system_resource(id)
      res = SystemResourceModuleConfigSchema.call(@sys_mod.to_h)
      return failed_message_from_validation(res) if res.failure?

      success_response('Config valid for module')
    end
  end
end
