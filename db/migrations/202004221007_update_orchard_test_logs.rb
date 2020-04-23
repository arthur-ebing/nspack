require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    run <<~SQL
      DROP TRIGGER log_orchard_test_result ON public.orchard_test_results;
      DROP FUNCTION public.fn_log_orchard_test_result();

      CREATE OR REPLACE FUNCTION public.fn_log_orchard_test_result()
        RETURNS TRIGGER
        AS
        $$
        BEGIN
          INSERT INTO orchard_test_logs
           (orchard_test_result_id,
            orchard_test_type_id,
            puc_id,
            orchard_id,
            cultivar_id,
            description,
            passed,
            freeze_result,
            api_result,
            api_response,
            classification,
            applicable_from,
            applicable_to,
            active,
            created_at,
            updated_at)
          VALUES 
           (NEW.id,
            NEW.orchard_test_type_id,
            NEW.puc_id,
            NEW.orchard_id,
            NEW.cultivar_id,
            NEW.description,
            NEW.passed,
            NEW.freeze_result,
            NEW.api_result,
            NEW.api_response,
            NEW.classification,
            NEW.applicable_from,
            NEW.applicable_to,
            NEW.active,
            NEW.created_at,
            NEW.updated_at);
          RETURN NEW;
          END;
         $$
        LANGUAGE plpgsql;

      CREATE TRIGGER log_orchard_test_result
      AFTER UPDATE
      ON public.orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_log_orchard_test_result();
    SQL
  end

  down do
    run <<~SQL
      DROP TRIGGER log_orchard_test_result ON public.orchard_test_results;
      DROP FUNCTION public.fn_log_orchard_test_result();

      CREATE OR REPLACE FUNCTION public.fn_log_orchard_test_result()
        RETURNS TRIGGER
        AS
        $$
        BEGIN
          INSERT INTO orchard_test_logs
           (orchard_test_result_id,
            orchard_test_type_id,
            puc_id,
            orchard_id,
            cultivar_id,
            description,
            passed,
            classification_only,
            freeze_result,
            api_result,
            classification,
            applicable_from,
            applicable_to,
            active,
            created_at,
            updated_at)
          VALUES 
           (NEW.id,
            NEW.orchard_test_type_id,
            NEW.puc_id,
            NEW.orchard_id,
            NEW.cultivar_id,
            NEW.description,
            NEW.passed,
            NEW.classification_only,
            NEW.freeze_result,
            NEW.api_result,
            NEW.classification,
            NEW.applicable_from,
            NEW.applicable_to,
            NEW.active,
            NEW.created_at,
            NEW.updated_at);
          RETURN NEW;
          END;
         $$
        LANGUAGE plpgsql;

      CREATE TRIGGER log_orchard_test_result
      AFTER UPDATE
      ON public.orchard_test_results
      FOR EACH ROW
      EXECUTE PROCEDURE public.fn_log_orchard_test_result();
    SQL
  end
end
