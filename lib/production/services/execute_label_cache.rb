# frozen_string_literal: true

module ProductionApp
  module ExecuteLabelCache
    def create_carton_label_cache # rubocop:disable Metrics/AbcSize
      cache = {}
      repo.allocated_setup_keys(production_run.id).each do |rec|
        cache[rec[:system_resource_code]] = {
          print_command: print_command_for(rec[:product_resource_allocation_id], rec[:label_template_name]),
          setup_data: rec[:setup_data],
          production_run_data: cache_run.merge(product_resource_allocation_id: rec[:product_resource_allocation_id],
                                               resource_id: rec[:resource_id],
                                               packing_method_id: rec[:packing_method_id],
                                               label_name: rec[:label_template_name])
        }
      end
      FileUtils.mkpath(AppConst::LABELING_CACHED_DATA_FILEPATH)
      File.open(File.join(AppConst::LABELING_CACHED_DATA_FILEPATH, "line_#{production_run.production_line_id}.yml"), 'w') { |f| f << cache.to_yaml }
    end

    def cache_run # rubocop:disable Metrics/AbcSize
      @cache_run ||= {
        production_run_id: production_run[:id],
        farm_id: production_run[:farm_id],
        puc_id: production_run[:puc_id],
        orchard_id: production_run[:orchard_id],
        cultivar_group_id: production_run[:cultivar_group_id],
        cultivar_id: production_run[:cultivar_id],
        packhouse_resource_id: production_run[:packhouse_resource_id],
        production_line_id: production_run[:production_line_id],
        season_id: production_run[:season_id]
      }
    end

    def print_command_for(product_resource_allocation_id, label_template_name)
      instance = messcada_repo.allocated_product_setup_label_printing_instance(product_resource_allocation_id)
      res = LabelPrintingApp::PrintCommandForLabel.call(label_template_name, instance)
      raise res.message unless res.success

      res.instance.print_command
    end
  end
end
