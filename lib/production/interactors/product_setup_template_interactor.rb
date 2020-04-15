# frozen_string_literal: true

module ProductionApp
  class ProductSetupTemplateInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_product_setup_template(params) # rubocop:disable Metrics/AbcSize
      res = validate_product_setup_template_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_product_setup_template(res)
        log_status('product_setup_templates', id, 'CREATED')
        log_transaction
      end
      instance = product_setup_template(id)
      success_response("Created product setup template #{instance.template_name}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { template_name: ['This product setup template already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_product_setup_template(id, params)  # rubocop:disable Metrics/AbcSize
      res = validate_product_setup_template_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_product_setup_template(id, res.to_h)
        log_transaction
      end
      instance = product_setup_template(id)
      success_response("Updated product setup template #{instance.template_name}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_product_setup_template(id)
      name = product_setup_template(id).template_name
      return failed_response("You cannot delete product setup template #{name}. It is on an active production run") if repo.product_setup_template_in_production?(id)

      repo.transaction do
        repo.delete_product_setup_template(id)
        log_status('product_setup_templates', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted product setup template #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ProductSetupTemplate.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def for_select_cultivar_group_cultivars(cultivar_group_id)
      MasterfilesApp::CultivarRepo.new.for_select_cultivars(where: { cultivar_group_id: cultivar_group_id })
    end

    def for_select_packhouse_lines(packhouse_id)
      ProductionApp::ProductSetupRepo.new.for_select_packhouse_lines(packhouse_id)
    end

    def for_select_season_group_seasons(season_group_id)
      MasterfilesApp::CalendarRepo.new.for_select_seasons(where: { season_group_id: season_group_id })
    end

    def activate_product_setup_template(id)
      repo.transaction do
        repo.activate_product_setup_template(id)
        log_status('product_setup_templates', id, 'ACTIVATED')
        log_transaction
      end
      instance = product_setup_template(id)
      success_response("Activated product setup template #{instance.template_name}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def deactivate_product_setup_template(id)
      repo.transaction do
        repo.deactivate_product_setup_template(id)
        log_status('product_setup_templates', id, 'DEACTIVATED')
        log_transaction
      end
      instance = product_setup_template(id)
      success_response("De-activated product setup template #{instance.template_name}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_product_setup_template(id, params)  # rubocop:disable Metrics/AbcSize
      res = validate_product_setup_template_params(params.to_h.reject { |k, _| k == :id })
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        new_product_setup_template_id = repo.create_product_setup_template(res)
        repo.clone_product_setup_template(id, new_product_setup_template_id)
        log_status('product_setup_templates', id, 'CLONED')
        log_transaction
      end
      instance = product_setup_template(id)
      success_response("Cloned product setup template #{instance.template_name}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= ProductSetupRepo.new
    end

    def product_setup_template(id)
      repo.find_product_setup_template(id)
    end

    def validate_product_setup_template_params(params)
      ProductSetupTemplateSchema.call(params)
    end
  end
end
