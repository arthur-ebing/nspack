# frozen_string_literal: true

namespace :app do
  namespace :edi do
    desc 'Send a PS EDI'
    task :send_ps, %i[org_code role] => [:load_app] do |_, args|
      repo = MasterfilesApp::PartyRepo.new
      id = if args.role.nil_or_empty? || args.role == 'marketer'
             repo.find_party_role_from_org_code_for_role(args.org_code, AppConst::ROLE_MARKETER)
           else
             repo.find_party_role_from_org_code_for_role(args.org_code, AppConst::ROLE_TARGET_CUSTOMER)
           end
      raise Crossbeams::InfoError, "Party #{args.org_code} does not exist as a marketer/target_customer" if id.nil?

      res = EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_PS, id, 'System')
      unless res.success
        puts 'Send failed:'
        puts res.message
      end
    end

    desc 'Send a UISTK EDI'
    task :send_uistk, %i[org_code] => [:load_app] do |_, args|
      repo = MasterfilesApp::PartyRepo.new
      id = repo.find_party_role_from_org_code_for_role(args.org_code, AppConst::ROLE_MARKETER)
      raise Crossbeams::InfoError, "Party #{args.org_code} does not exist as a marketer" if id.nil?

      res = EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_UISTK, id, 'System')
      unless res.success
        puts 'Send failed:'
        puts res.message
      end
    end
  end
end
