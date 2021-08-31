# frozen_string_literal: true

module ProductionApp
  module ExecuteLabelCache
    def create_carton_label_cache # rubocop:disable Metrics/AbcSize
      cache = {}
      repo.allocated_setup_keys(production_run.id).each do |rec|
        cultivar_id = production_run[:cultivar_id].nil_or_empty? ? repo.resolve_setup_cultivar_id(rec[:product_setup_id]) : production_run[:cultivar_id]
        cache[rec[:device_or_packpoint]] = {
          print_command: print_command_for(rec[:product_resource_allocation_id], rec[:label_template_name]),
          setup_data: rec[:setup_data],
          production_run_data: cache_run.merge(product_resource_allocation_id: rec[:product_resource_allocation_id],
                                               resource_id: rec[:resource_id],
                                               packing_method_id: rec[:packing_method_id],
                                               label_name: rec[:label_template_name],
                                               target_customer_party_role_id: rec[:target_customer_party_role_id],
                                               cultivar_id: cultivar_id,
                                               legacy_data: resolve_run_legacy_data(production_run.legacy_data.to_h))
        }
      end
      FileUtils.mkpath(AppConst::LABELING_CACHED_DATA_FILEPATH)

      # Write the cache file with an exclusive lock to prevent reads before it is fully written.
      File.open(File.join(AppConst::LABELING_CACHED_DATA_FILEPATH, "line_#{production_run.production_line_id}.yml"), File::TRUNC | File::WRONLY | File::CREAT) do |f|
        f.flock(File::LOCK_EX)
        f << cache.to_yaml
      end
    end

    def cache_run
      @cache_run ||= {
        production_run_id: production_run[:id],
        farm_id: production_run[:farm_id],
        puc_id: production_run[:puc_id],
        orchard_id: production_run[:orchard_id],
        cultivar_group_id: production_run[:cultivar_group_id],
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

    def resolve_run_legacy_data(data)
      legacy_data = {}
      AppConst::CR_PROD.run_cache_legacy_data_fields.each { |column| legacy_data[column.to_s] = data[column.to_s] }
      legacy_data
    end
  end
end
