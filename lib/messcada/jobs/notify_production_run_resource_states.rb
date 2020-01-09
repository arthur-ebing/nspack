# frozen_string_literal: true

module MesscadaApp
  module Job
    class NotifyProductionRunResourceStates < BaseQueJob
      attr_reader :production_run_id, :xml

      def run(production_run_id)
        @production_run_id = production_run_id
        res = send_notification_for_resource_states

        unless res.success
          msg = <<~STR
            The response from MesServer call: #{res.message}

            The instance returned was:
            #{res.instance.inspect}
          STR
          ErrorMailer.send_error(subject: "#{self.class.name} failed to set button captions",
                                 message: msg)
        end
        finish
      end

      private

      def send_notification_for_resource_states
        build_xml
        send_xml
      end

      def build_caption(rec)
        return 'Not in use' if rec[:product_setup_id].nil_or_empty?

        ar = AppConst::CLM_BUTTON_CAPTION_FORMAT.split('$')
        ar.map { |s| s.start_with?(':') ? rec[s.delete_prefix(':').to_sym] : s }.compact.join
      end

      def build_xml # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        repo = ProductionApp::ProductionRunRepo.new
        if AppConst::CLM_BUTTON_CAPTION_FORMAT
          lbl_modules = repo.button_allocations(production_run_id)
          grp_modules = lbl_modules.group_by { |r| r[:module] }
        else
          grp_modules = {}
        end

        grp_bvm = if AppConst::PROVIDE_PACK_TYPE_AT_VERIFICATION
                    repo.bin_verification_settings(production_run_id)
                  else
                    {}
                  end

        builder = Nokogiri::XML::Builder.new do |xml| # rubocop:disable Metrics/BlockLength
          xml.module_buttons do # rubocop:disable Metrics/BlockLength
            xml.modules do # rubocop:disable Metrics/BlockLength
              unless grp_module.empty?
                grp_modules.each do |mod, buttons|
                  xml.module do
                    xml.name mod
                    xml.buttons do
                      buttons.each do |rec|
                        xml.button do
                          xml.name rec[:button]
                          xml.caption build_caption(rec)
                          xml.enabled !rec[:product_setup_id].nil?
                        end
                      end
                    end
                  end
                end
              end
              unless grp_bvm.empty?
                grp_bvm.each do |mod, buttons|
                  xml.module do
                    xml.name mod
                    xml.buttons do
                      buttons.each do |name, tare|
                        xml.button do
                          xml.name name
                          xml.caption tare.nil? ? 'Not in use' : tare.to_s('F')
                          xml.enabled !tare.nil?
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
        @xml = builder.to_xml
      end

      def send_xml
        http = Crossbeams::HTTPCalls.new
        http.xml_post("#{AppConst::LABEL_SERVER_URI}SetModuleButtonState", xml)
      end
    end
  end
end
