
Sequel.migration do
  up do
      rename_column :orchard_test_types, :result_attribute, :api_attribute
      add_column    :orchard_test_types, :api_result_pass, String

      rename_column  :orchard_test_results, :api_result, :api_response
      rename_column  :orchard_test_results, :classification, :api_result
      rename_column  :orchard_test_results, :classification_only, :classification

      rename_column :orchard_test_logs, :api_result, :api_response
      rename_column :orchard_test_logs, :classification, :api_result
      rename_column :orchard_test_logs, :classification_only, :classification
  end

  down do
      rename_column :orchard_test_logs, :classification, :classification_only
      rename_column :orchard_test_logs, :api_result, :classification
      rename_column :orchard_test_logs, :api_response, :api_result

      rename_column :orchard_test_results, :classification, :classification_only
      rename_column :orchard_test_results, :api_result, :classification
      rename_column :orchard_test_results, :api_response, :api_result

      drop_column   :orchard_test_types, :api_result_pass
      rename_column :orchard_test_types, :api_attribute, :result_attribute
  end
end
