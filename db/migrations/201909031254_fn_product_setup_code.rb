Sequel.migration do
  up do
    root_dir = File.expand_path('..', __dir__)
    sql = File.read(File.join(root_dir, 'ddl', 'functions', 'fn_product_setup_code.sql'))
    run sql

    sql = File.read(File.join(root_dir, 'ddl', 'functions', 'fn_product_setup_in_production.sql'))
    run sql
  end

  down do
    run 'DROP FUNCTION public.fn_product_setup_code(integer);'
    run 'DROP FUNCTION public.fn_product_setup_in_production(integer);'
  end
end
