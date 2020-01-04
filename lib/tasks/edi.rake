# frozen_string_literal: true

namespace :app do
  namespace :edi do
    desc 'Send a PS EDI'
    task :send_ps, [:org_code] => [:load_app] do |_, args|
      repo = MasterfilesApp::PartyRepo.new
      id = repo.find_party_role_from_party_name_for_role(args.org_code, AppConst::ROLE_MARKETER)
      raise Crossbeams::InfoError, "Party #{args.org_code} does not exist as a marketer" if id.nil?

      res = EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_PS, id, 'System')
      unless res.success
        puts 'Send failed:'
        puts res.message
      end
    end
  end
end
