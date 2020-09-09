# frozen_string_literal: true

namespace :app do
  namespace :stress do
    desc 'Print labels'
    task :print_many, %i[prn lbl no] => [:load_app] do |_, args|
      repo = MesserverApp::MesserverRepo.new

      template = MasterfilesApp::LabelTemplateRepo.new.find_label_template_by_name(args.lbl)
      vars = Hash[template.variables.each_with_index.map { |_, i| ["F#{i + 1}".to_sym, "AA-#{i + 1}"] }]

      ok = true
      args.no.to_i.times do
        res = repo.print_published_label(args.lbl, vars, 1, args.prn)
        if res.success
          print '.'
        else
          puts "\n\nERROR: #{res.message}"
          p res
          ok = false
          break
        end
      end
      if ok
        puts "\n\n#{args.no} labels printed"
      else
        puts "\n\nFailed..."
      end
    end
  end
end
