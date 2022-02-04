# frozen_string_literal: true

module ProductionApp
  class ValidateConfigPeripheral < BaseService
    attr_reader :id, :repo

    def initialize(id)
      @id = id
      @repo = ResourceRepo.new
    end

    def call # rubocop:disable Metrics/AbcSize
      @sys_mod = repo.find_system_resource(id)
      type = repo.plant_resource_type_code_for_system_resource(id)
      res = case type
            when Crossbeams::Config::ResourceDefinitions::PRINTER
              contract = SystemResourcePrinterConfigSchema.new(printer_set: Crossbeams::Config::ResourceDefinitions::PRINTER_SET)
              contract.call(@sys_mod.to_h)
            when Crossbeams::Config::ResourceDefinitions::SCALE
              contract = SystemResourceScaleConfigSchema.new
              contract.call(@sys_mod.to_h)
            when Crossbeams::Config::ResourceDefinitions::SCANNER
              contract = SystemResourceScannerConfigSchema.new
              contract.call(@sys_mod.to_h)
            else
              raise Crossbeams::FrameworkError, "Unknown peripheral type for validation: #{type}"
            end
      return failed_message_from_validation(res) if res.failure?

      success_response('Config valid for peripheral')
    end
  end
end
