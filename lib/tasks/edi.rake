# frozen_string_literal: true

namespace :app do
  namespace :edi do
    desc 'Send a PS EDI'
    task :send_ps, [:org_code] => [:load_app] do |_, args|
      EdiApp::Job::SendEdiOut.enqueue(AppConst::EDI_FLOW_PS, args.org_code, 'System')
    end
  end
end
