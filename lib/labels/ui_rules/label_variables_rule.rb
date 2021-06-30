# frozen_string_literal: true

module UiRules
  class LabelVariablesRule < Base
    def generate_rules
      @repo = LabelApp::SharedConfigRepo.new

      rules[:data] = []
      AppConst::LABEL_VARIABLE_SETS.each do |variable_set|
        data = @repo.remote_object_config_for(variable_set)
        hash = { set: variable_set, apps: [] }
        mod_hash(hash, data)
        rules[:data] << hash
      end
      # read shared config
    end

    def mod_hash(hash, data) # rubocop:disable Metrics/AbcSize
      keys = Set.new
      data.each { |_, v| v[:applications].each { |a| keys << a } }
      keys.sort.each do |app|
        hs = { app: app, rows: [] }
        data.each do |k, v|
          hs[:rows] << { variable: k, group: v[:group], resolver: v[:resolver] } if v[:applications].include?(app)
        end
        hash[:apps] << hs
      end
    end
  end
end
