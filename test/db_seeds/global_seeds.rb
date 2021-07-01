# frozen_string_literal: true

# Run masterfile seeds on test suite loading.
class GlobalSeedRunner
  def run_masterfile_setup
    root_dir = File.expand_path('../../..', __FILE__)
    script = File.read(File.join(root_dir, 'db/seeds/20_masterfile_data.sql'))
    DB.execute(script) 
  end

  def run_gln_setup
    AppConst::GLN_OR_LINE_NUMBERS.each do |gln|
      return if gln.nil? || gln.empty?

      seq_name = "gln_seq_for_#{gln}"
      query = "SELECT EXISTS(SELECT 0 FROM pg_class where relname = '#{seq_name}')"
      return if DB[query].single_value

      DB.run("CREATE SEQUENCE #{seq_name}")
    end
  end
end

runner = GlobalSeedRunner.new
runner.run_gln_setup
# runner.run_masterfile_setup
