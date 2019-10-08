# frozen_string_literal: true

module MesscadaApp
  class MesscadaRepo < BaseRepo
    def get_rmt_bin_setup_reqs(bin_id)
      DB["select b.id, b.farm_id, b.orchard_id, b.cultivar_id
        ,c.cultivar_name, c.cultivar_group_id, cg.cultivar_group_code,f.farm_code, o.orchard_code
        from rmt_bins b
        join cultivars c on c.id=b.cultivar_id
        join cultivar_groups cg on cg.id=c.cultivar_group_id
        join farms f on f.id=b.farm_id
        join orchards o on o.id=b.orchard_id
        WHERE b.id = ?", bin_id].first
    end

    def get_run_setup_reqs(run_id)
      DB["select r.id, r.farm_id, r.orchard_id, r.cultivar_group_id, r.cultivar_id, r.allow_cultivar_mixing, r.allow_orchard_mixing
        ,c.cultivar_name, cg.cultivar_group_code,f.farm_code, o.orchard_code, p.puc_code
        from production_runs r
        join cultivars c on c.id=r.cultivar_id
        join cultivar_groups cg on cg.id=r.cultivar_group_id
        join farms f on f.id=r.farm_id
        join orchards o on o.id=r.orchard_id
        join pucs p on p.id=r.puc_id
        WHERE r.id = ?", run_id].first
    end

    def production_run_stats(run_id)
      DB[:production_run_stats].where(production_run_id: run_id).map { |p| p[:bins_tipped] }.first
    end
  end
end
