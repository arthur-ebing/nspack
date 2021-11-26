# frozen_string_literal: true

module ProductionApp
  class ProvisionDevice < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :id, :repo, :network_ip, :usr, :pw, :out, :use_network_ip

    def initialize(id, network_ip, use_network_ip)
      @id = id
      @network_ip = network_ip
      @use_network_ip = use_network_ip
      @repo = ResourceRepo.new
      @usr = 'nspi'
      @pw = 'e=mc22'
      @out = []
    end

    def call # rubocop:disable Metrics/AbcSize
      sys_mod = repo.find_system_resource_flat(id)
      out << "PROVISIONING #{sys_mod.system_resource_code} ip: #{sys_mod.ip_address}"
      out << "---------------------------------------\n"
      AppConst::ROBOT_LOG.info('Starting provisioning of a device')
      AppConst::ROBOT_LOG.info("PROVISIONING #{sys_mod.system_resource_code} ip: #{sys_mod.ip_address}")
      res = check_for_previously_provisioned
      AppConst::ROBOT_LOG.info('Provisioning aborted - already run for this device') unless res.success
      return res unless res.success

      add_user
      show_mac
      copy_splash
      config_splash_locale_autostart
      copy_messerver_set_host

      copy_robot_config
      reboot

      AppConst::ROBOT_LOG.info('Provisioning complete.')
      success_response('Device has been provisioned and is rebooting', out)
    end

    private

    def copy_robot_config
      res = if use_network_ip
              ProductionApp::BuildModuleConfigXml.call(id, alternate_ip: network_ip)
            else
              ProductionApp::BuildModuleConfigXml.call(id)
            end

      Net::SCP.start(network_ip, usr, password: pw) do |scp|
        scp.upload! StringIO.new(res.instance[:xml]), '/home/nspi/nosoft/messerver/config/config.xml'
        out << 'Config.xml copied to device'
      end
    end

    def reboot
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << 'Reboot...'
        ssh.exec!('sudo reboot')
      end
    end

    def add_user # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, 'pi', password: 'raspberry') do |ssh|
        out << "Add nspi user and change the pi user's password"
        out << ssh.exec!(%(sudo useradd -s /bin/bash -d /home/nspi/ -m -G sudo,adm,lpadmin,gpio,dialout,cdrom,audio,video,input,netdev,i2c,spi nspi))
        out << ssh.exec!(%(sudo usermod --password $(openssl passwd -1 '#{pw}') nspi))
        out << ssh.exec!(%(echo 'nspi ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/010_nspi-nopasswd))
        out << ssh.exec!(%(sudo sed -i "s/autologin-user=pi/autologin-user=nspi/" /etc/lightdm/lightdm.conf))
        out << ssh.exec!(%(sudo usermod --password $(openssl passwd -1 '#{pw}') pi))
      end
      # Thread.new { send_bus_message_to_page([], 'list/system_resources', message: out.last) }
    end

    def show_mac # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        result = ssh.exec!(%(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address))
        out << 'MAC address:'
        out << '-----------------'
        out << result.chomp
        out << '-----------------'

        out << 'Adding aliases to bashrc'
        ssh.exec!(%(echo "alias lsl='ls -lht | head'" >> .bashrc))
        ssh.exec!(%(echo "alias killmesserver='sudo pkill -f java\\.+messerver'" >> .bashrc))
        # Thread.new { send_bus_message_to_page([], 'list/system_resources', message: out.last) }

        out << 'Remove the default pi startup script'
        ssh.exec!(%(sudo rm /etc/xdg/autostart/piwiz.desktop))
        # Thread.new { send_bus_message_to_page([], 'list/system_resources', message: out.last) }
      end
    end

    def copy_splash
      Net::SCP.start(network_ip, usr, password: pw) do |scp|
        out << 'Copy NoSoft splash screen to device'
        # if seeed / pi... [SYS: add hardware_device (rpi, radUDP, reterm, radJSON, ITPC, browser, android)
        scp.upload! "#{ENV['ROOT']}/device_provisioning/ns_splash.png", '/home/nspi/ns_splash.png'
        # scp.upload! "#{ENV['ROOT']}/device_provisioning/ns_splash_vert.png", '/home/nspi/ns_splash.png'
      end
    end

    def config_splash_locale_autostart # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, usr, password: pw) do |ssh| # rubocop:disable Metrics/BlockLength
        out << 'Set up splash screen'
        # For pi
        ssh.exec!(%(cd /usr/share/plymouth/themes/pix/))
        ssh.exec!(%(sudo mv splash.png splash.png.bk))
        ssh.exec!(%(sudo mv /home/nspi/ns_splash.png /usr/share/plymouth/themes/pix/splash.png))

        # For reTerm
        # ssh.exec!(%(cd /usr/share/plymouth/themes/seeed/))
        # ssh.exec!(%(sudo mv splash_v.png splash_v.png.bk))
        # ssh.exec!(%(sudo mv /home/nspi/ns_splash_vert.png /usr/share/plymouth/themes/seeed/splash_v.png))
        # convert tty1 to tty3?
        out << 'Update apt'
        ssh.exec!(%(sudo apt-get update -y))

        out << 'Make locale and date settings'
        ssh.exec!(%(sudo cp /etc/locale.gen /etc/locale.gen.dist))
        ssh.exec!(%(sudo sed -i -e "/^[^#]/s/^/# /" -e "/en_ZA.UTF-8/s/^# //" /etc/locale.gen))
        ssh.exec!(%(sudo cp /var/cache/debconf/config.dat /var/cache/debconf/config.dat.dist))
        ssh.exec!(%(sudo sed -i -e "/^Value: en_GB.UTF-8/s/en_GB/en_ZA/" -e "/^ locales = en_GB.UTF-8/s/en_GB/en_ZA/" /var/cache/debconf/config.dat))
        ssh.exec!(%(sudo locale-gen))
        ssh.exec!(%(sudo update-locale LANG=en_ZA.UTF-8))
        ssh.exec!(%(sudo update-locale LANGUAGE=en_ZA.UTF-8))
        ssh.exec!(%(sudo timedatectl set-timezone Africa/Johannesburg))
        ssh.exec!(%(sudo cp /etc/default/keyboard /etc/default/keyboard.dist))
        ssh.exec!(%(sudo sed -i -e "/XKBLAYOUT=/s/gb/us/" /etc/default/keyboard))
        ssh.exec!(%(sudo service keyboard-setup restart))

        # out << 'Install vim'
        # result = ssh.exec!(%(sudo apt-get install vim -y))
        # out << result
        # out << 'Install minicom'
        # result = ssh.exec!(%(sudo apt-get install minicom -y))
        # out << result
        # out << 'Install lsof'
        # result = ssh.exec!(%(sudo apt-get install lsof -y))
        # out << result
        # out << 'Install java'
        # result = ssh.exec!(%(sudo apt-get install openjdk-8-jdk -y)) unless for_virtual_pi
        # out << result
        out << 'Disable java assistive technologies'
        result = ssh.exec!(%(sudo sed -i -e '/^assistive_technologies=/s/^/#/' /etc/java-*-openjdk/accessibility.properties))
        out << result

        out << 'Disable ipv6'
        ssh.exec!(%(echo 'net.ipv6.conf.all.disable_ipv6 = 0' | sudo tee -a /etc/sysctl.conf))

        out << 'Disable WiFi && Bluetooth'
        ssh.exec!(%(echo 'dtoverlay=disable-wifi' | sudo tee -a /boot/config.txt))
        ssh.exec!(%(echo 'dtoverlay=disable-bt' | sudo tee -a /boot/config.txt))

        out << 'Set boot to wait for network:'
        ssh.exec!(%(sudo mkdir -p /etc/systemd/system/dhcpcd.service.d/))
        result = ssh.exec!(<<~STR)
          cat <<- EOF | sudo tee /etc/systemd/system/dhcpcd.service.d/wait.conf
          [Service]
          ExecStart=
          ExecStart=/usr/lib/dhcpcd5/dhcpcd -q -w
          EOF
        STR
        out << result

        out << 'Logrotate for MesServer'
        result = ssh.exec!(<<~STR)
          cat << EOF | sudo tee /etc/logrotate.d/messerver
          /home/nspi/nosoft/messerver/logs/stdoutlog.log {
            daily
            missingok
            rotate 3
            compress
            copytruncate
            delaycompress
          }
          EOF
        STR
        out << result

        out << 'Autostart into kiosk'
        # 1. Comment out all existing lines:
        ssh.exec!(%(sudo sed -i 's/^\\([^#]\\)/# \\1/g' /etc/xdg/lxsession/LXDE-pi/autostart))
        # 2. Add kiosk-enabling lines
        result = ssh.exec!(<<~STR)
          cat << EOF | sudo tee -a /etc/xdg/lxsession/LXDE-pi/autostart
          @xset s 0 0
          @xset s noblank
          @xset s noexpose
          @xset dpms 0 0 600
          # Kiosk mode: Start only the java app:
          @/home/nspi/nosoft/messerver/startMesServer.sh
          EOF
        STR
        out << result
      end
    end

    def copy_messerver_set_host # rubocop:disable Metrics/AbcSize
      Net::SCP.start(network_ip, usr, password: pw) do |scp|
        out << 'Copy MesServer zip file to device'
        scp.upload! "#{ENV['ROOT']}/device_provisioning/nosoft_messerver.zip", '/home/nspi/nosoft_messerver.zip'
      end

      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << 'Unzip messerver'
        out << ssh.exec!(%(unzip nosoft_messerver.zip))
        out << ssh.exec!(%(rm nosoft_messerver.zip))
        out << ssh.exec!(%(sed -i "s/^java /# java /" /home/nspi/nosoft/messerver/startMesServer.sh)) # if for_virtual_pi
        out << ssh.exec!(%(sed -i "s/^# JAVA 11: //g" /home/nspi/nosoft/messerver/startMesServer.sh)) # if for_virtual_pi

        out << 'Change the hostname and static ip address'
        out << ssh.exec!(%(sudo sed -i "s/raspberry/ns-#{network_ip.tr('.', '')}/g" /etc/hostname))
        out << ssh.exec!(%(sudo sed -i "s/raspberrypi/ns-#{network_ip.tr('.', '')}/g" /etc/hostname))
        out << ssh.exec!(%(sudo sed -i "s/raspberrypi/ns-#{network_ip.tr('.', '')}/g" /etc/hosts))
      end
    end

    def check_for_previously_provisioned
      Net::SSH.start(network_ip, 'pi', password: 'raspberry', non_interactive: true) do |ssh|
        ssh.exec!('ls -l')
      end
      ok_response
    rescue Net::SSH::AuthenticationFailed
      failed_response('This device has already been provisioned', ['Unable to re-provision device'])
    end
  end
end
