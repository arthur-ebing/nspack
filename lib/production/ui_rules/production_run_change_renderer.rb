# frozen_string_literal: true

module UiRules
  class ProductionRunChangeRenderer < BaseChangeRenderer
    def changed_packhouse
      res = options[:interactor].lines_for_packhouse(params)
      if res.success
        router.json_replace_select_options('production_run_production_line_id', res.instance)
      else
        router.show_json_error(res.message)
      end
    end

    def changed_farm # rubocop:disable Metrics/AbcSize
      res = options[:interactor].change_for_farm(params)
      if res.success
        build_actions(replace_select_options: [
                        { dom_id: 'production_run_puc_id', options: res.instance[:pucs] },
                        { dom_id: 'production_run_orchard_id', options: res.instance[:orchards] },
                        { dom_id: 'production_run_cultivar_group_id', options: res.instance[:cultivar_groups] },
                        { dom_id: 'production_run_cultivar_id', options: res.instance[:cultivars] },
                        { dom_id: 'production_run_season_id', options: res.instance[:seasons] }
                      ])
      else
        router.show_json_error(res.message)
      end
    end

    def changed_puc # rubocop:disable Metrics/AbcSize
      res = options[:interactor].change_for_puc(params)
      if res.success
        build_actions(replace_select_options: [
                        { dom_id: 'production_run_orchard_id', options: res.instance[:orchards] },
                        { dom_id: 'production_run_cultivar_group_id', options: res.instance[:cultivar_groups] },
                        { dom_id: 'production_run_cultivar_id', options: res.instance[:cultivars] },
                        { dom_id: 'production_run_season_id', options: res.instance[:seasons] }
                      ])
      else
        router.show_json_error(res.message)
      end
    end

    def changed_orchard
      res = options[:interactor].change_for_orchard(params)
      if res.success
        build_actions(replace_select_options: [
                        { dom_id: 'production_run_cultivar_group_id', options: res.instance[:cultivar_groups] },
                        { dom_id: 'production_run_cultivar_id', options: res.instance[:cultivars] }
                      ])
      else
        router.show_json_error(res.message)
      end
    end

    def changed_cultivar_group
      res = options[:interactor].change_for_cultivar_group(params)
      if res.success
        build_actions(replace_select_options: [
                        { dom_id: 'production_run_cultivar_id', options: res.instance[:cultivars] },
                        { dom_id: 'production_run_season_id', options: res.instance[:seasons] }
                      ])
      else
        router.show_json_error(res.message)
      end
    end
  end
end
