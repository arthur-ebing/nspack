# frozen_string_literal: true

module MesscadaApp
  module Job
    class NotifyProductionRunResourceStates < BaseQueJob
      attr_reader :production_run_id, :xml, :repo

      def run(production_run_id)
        @production_run_id = production_run_id
        @repo = ProductionApp::ProductionRunRepo.new
        res = send_notification_for_resource_states

        unless res.success
          msg = <<~STR
            The response from MesServer call: #{res.message}

            The instance returned was:
            #{res.instance.inspect}
          STR
          ErrorMailer.send_error_email(subject: "#{self.class.name} failed to set button captions",
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
        return 'No template' if rec[:label_template_id].nil_or_empty?

        # ar = AppConst::CLM_BUTTON_CAPTION_FORMAT.split('$')
        ar = AppConst::CR_PROD.button_caption_spec.split('$')
        ar.map { |s| s.start_with?(':') ? rec[s.delete_prefix(':').to_sym] : s }.compact.join
      end

      def build_xml # rubocop:disable Metrics/AbcSize
        modules_for_lbl = clm_modules
        modules_for_bvm = bvm_modules

        builder = Nokogiri::XML::Builder.new do |xml| # rubocop:disable Metrics/BlockLength
          xml.module_buttons do # rubocop:disable Metrics/BlockLength
            xml.modules do # rubocop:disable Metrics/BlockLength
              unless modules_for_lbl.empty?
                modules_for_lbl.each do |mod, buttons|
                  xml.module do
                    xml.name mod.first
                    xml.alias mod.last
                    xml.buttons do
                      buttons.each do |rec|
                        xml.button do
                          xml.name rec[:button]
                          xml.caption build_caption(rec)
                          xml.enabled !rec[:product_setup_id].nil? && !rec[:label_template_id].nil?
                        end
                      end
                    end
                  end
                end
              end
              unless modules_for_bvm.empty?
                modules_for_bvm.each do |mod, buttons|
                  xml.module do
                    xml.name mod.first
                    xml.alias mod.last
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

      def clm_modules
        # return {} unless AppConst::CLM_BUTTON_CAPTION_FORMAT
        return {} unless CR_PROD.button_caption_spec

        lbl_modules = repo.button_allocations(production_run_id)
        lbl_modules.group_by { |r| [r[:module], r[:alias]] }
      end

      def bvm_modules
        # return {} unless AppConst::PROVIDE_PACK_TYPE_AT_VERIFICATION
        return {} unless AppConst::CR_PROD.provide_pack_type_at_carton_verification?

        repo.bin_verification_settings(production_run_id)
      end

      def send_xml
        http = Crossbeams::HTTPCalls.new
        http.xml_post("#{AppConst::LABEL_SERVER_URI}SetModuleRobotButtonStates", xml)
      end
    end
  end
end
