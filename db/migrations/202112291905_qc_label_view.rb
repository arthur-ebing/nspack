Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE VIEW public.vw_qc_sample_label
      AS SELECT qc_samples.id AS sample_id,
        qc_sample_types.qc_sample_type_name,
        qc_samples.drawn_at::date AS sample_date,
        CASE WHEN qc_samples.rmt_delivery_id IS NOT NULL THEN
          'Delivery'
        WHEN qc_samples.coldroom_location_id IS NOT NULL THEN
          'Coldroom'
        WHEN qc_samples.production_run_id IS NOT NULL THEN
          'Production run'
        WHEN qc_samples.orchard_id IS NOT NULL THEN
          'Orchard'
        WHEN qc_samples.presort_run_lot_number IS NOT NULL THEN
          'Presort lot'
        END AS context,
        CASE WHEN qc_samples.rmt_delivery_id IS NOT NULL THEN
          qc_samples.rmt_delivery_id::text
        WHEN qc_samples.coldroom_location_id IS NOT NULL THEN
          locations.location_long_code
        WHEN qc_samples.production_run_id IS NOT NULL THEN
          qc_samples.production_run_id::text
        WHEN qc_samples.orchard_id IS NOT NULL THEN
          orchards.orchard_code
        WHEN qc_samples.presort_run_lot_number IS NOT NULL THEN
          qc_samples.presort_run_lot_number
        END AS context_ref,
        qc_samples.ref_number,
        qc_samples.short_description,
        qc_samples.sample_size,
        -- Presort
        qc_samples.presort_run_lot_number,
        -- Delivery
        farms.farm_code,
        rmt_codes.rmt_code,
        -- Orchard
        orchards.orchard_code,
        -- Coldroom
        locations.location_long_code,
        locations.location_short_code,
        locations.print_code,
        locations.location_description,
        -- Production Run
        qc_samples.production_run_id
      FROM qc_samples
      JOIN qc_sample_types ON qc_sample_types.id = qc_samples.qc_sample_type_id
      LEFT JOIN rmt_deliveries ON rmt_deliveries.id = qc_samples.rmt_delivery_id 
      LEFT JOIN farms ON farms.id = rmt_deliveries.farm_id 
      LEFT JOIN rmt_codes ON rmt_codes.id = rmt_deliveries.rmt_code_id 
      LEFT JOIN locations ON locations.id = qc_samples.coldroom_location_id
      LEFT JOIN orchards ON orchards.id = qc_samples.orchard_id;
        
      ALTER TABLE public.vw_qc_sample_label
      OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_qc_sample_label;
    SQL
  end
end
