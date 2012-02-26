# encoding: utf-8
# tested with ruby 1.9.3

module X module Supervision module Clusters
  require_relative '../0x1_lib.helper.rb'

  OSES = [
    'ub10.04_x86_64',
    'ub11.04_x86_64'
  ]

  CLUSTER_TYPES = [
    'cluster.core',
    'cluster.leaf'
  ]

  CLUSTER_TYPE_SHORTNAMES = {
    'cluster.core' => 'cc',
    'cluster.leaf' => 'cf'
  }


  RAW_SSH_COMMAND_INITIAL_AUTHORIZED_KEYS = <<XHEREDOC
#!/usr/bin/env bash
sup_ssh_pubkey="@@_0x1_sup_ssh_pubkey_@@"

user_home_dir=$(cd ~ ; pwd)
user_ssh_dir="${user_home_dir}/.ssh"
if [[ -d "${user_ssh_dir}.0ring_ini" ]]
then
    echo "ERROR: directory ${user_ssh_dir}.0ring_ini exists already"
    exit 1
fi
if [[ -d "${user_ssh_dir}" ]]
then
    echo "${user_ssh_dir}"
    mv "${user_ssh_dir}" "${user_ssh_dir}.0ring_ini"
    echo "moving initial ssh dir"
fi
mkdir ${user_ssh_dir}
chmod 700 ${user_ssh_dir}
user_authorized_keys_file="${user_ssh_dir}/authorized_keys"
echo ${sup_ssh_pubkey} > ${user_authorized_keys_file}
chmod 600 ${user_authorized_keys_file}
ls -al ${user_ssh_dir}
XHEREDOC


# TODO: merge phases 1 and 2 classes into main ClusterIni class
class ClusterIni
def initialize(os, cluster_type, x_0ring_version)
  x__load_modules([:standard, :onlline])
  @os = os
  abort "ERROR: invalid cluster_type (#{cluster_type}" unless valid_os?(os)
  @cluster_type = cluster_type if valid_cluster_type?(cluster_type)
  @cluster_type_shortname = cluster_type_shortname(@cluster_type)
  @x_0ring_version = x_0ring_version
  @x_0ring_current = "#{@cluster_type_shortname}#{@x_0ring_version}"
  @x_user_homedir = x__user_homedir
  xsup_ssh_pub_key_file = "#{@x_user_homedir}/.ssh/id_rsa.pub"
  abort "XERROR: can't access xsup_ssh_pub_key_file ("+
    "#{xsup_ssh_pub_key_file})" unless x__is_a_file?(xsup_ssh_pub_key_file) \
    or x__is_a_symlink?(xsup_ssh_pub_key_file)
  @xsup_ssh_pub_key = x__file_read_chomp(xsup_ssh_pub_key_file)
  @x_supervision_new_cluster_basedir = \
    "#{@x_user_homedir}/.0x1.sup/cluster.new"
  @x_ini_0ring_dir = ".0x1.ini.0ring"
  @x_ini_0ring_basedir = "#{@x_supervision_new_cluster_basedir}/"+
    "#{@x_ini_0ring_dir}"
  @x_ini_0ring_logsdir = "#{@x_supervision_new_cluster_basedir}"+
    "/.0x1.ini.0ring/logs"
  @x_ini_0ring_data_filepath = "#{@x_ini_0ring_basedir}/.0x1.ini.0ring.data.rb"
end

def valid_os?(os)
  x__array_value_exist?(OSES, os)
end

def valid_cluster_type?(cluster_type)
  x__array_value_exist?(CLUSTER_TYPES, cluster_type)
end

def cluster_type_shortname(cluster_type)
  CLUSTER_TYPE_SHORTNAMES[cluster_type]
end

end

  class ClusterIniPhase1 < ClusterIni

    def initialize(os, cluster_type, x_0ring_version)
      super
      x__mkdir_p(@x_supervision_new_cluster_basedir) \
        unless x__is_a_dir?(@x_supervision_new_cluster_basedir)
      abort "ERROR: can't access neither create supervision basedir "+
        "(#{@x_supervision_new_cluster_basedir})" \
        unless x__is_a_dir?(@x_supervision_new_cluster_basedir)
      abort "ERROR: when starting new cluster installation, "+
        "x_supervision_new_cluster_basedir should be empty "+
        "(#{@x_supervision_new_cluster_basedir})" \
        unless x__dir_is_empty?(@x_supervision_new_cluster_basedir)
      abort "ERROR: invalid os type (#{os}" unless valid_os?(os)
      download_raw_install_ini_dir
      puts "\n\n0x1.cluster_ini_phase1 completed. When datafile is filled "+
        "#{@x_ini_0ring_data_filepath}, please run again\n\n"+
        "x.cluster_ini_0ring.#{@x_0ring_current}\n\n"
      %x"e #{@x_ini_0ring_data_filepath}"
      x_ini_0ring_phase1_done_file = "#{@x_ini_0ring_logsdir}/"+
        "x.cluster_ini_0ring.#{@x_0ring_current}.phase1.done"
      x__file_save_nl(x__datetime_sec, x_ini_0ring_phase1_done_file)
      abort "ERROR: can't process ini phase1 done log file" \
        unless x__is_a_file?(x_ini_0ring_phase1_done_file)
      ClusterIniPhase2.new(@os, @cluster_type, @x_0ring_version)
    end


    private

    def download_raw_install_ini_dir()
      # dowloading raw ini dir archive
      puts "XDEBUG: https://raw.github.com/0xyl1s/0x1_supervision_templates/"+
        "master/#{@os}/0rings/#{@cluster_type}/ini_0ring_templates/"+
        "variation_01/.0x1.ini.0ring.tar.uri"
      ini_dir_archive_uri = x__read_uri_content("https://raw.github.com/"+
        "0xyl1s/0x1_supervision_templates/master/#{@os}/0rings/"+
        "#{@cluster_type}/ini_0ring_templates/variation_01/"+
        ".0x1.ini.0ring.tar.uri")
      puts "XDEBUG: ini_dir_archive_uri = #{ini_dir_archive_uri}"
      x__http_download_and_save(ini_dir_archive_uri, \
        @x_supervision_new_cluster_basedir)
      # extracting ini dir tar archive
      %x"cd #{@x_supervision_new_cluster_basedir} ;\
        tar xvf ./.0x1.ini.0ring.tar"
      abort "ERROR: can't access @x_ini_0ring_basedir "+
        "(#{@x_ini_0ring_basedir})"\
        unless x__is_a_dir?(@x_ini_0ring_basedir)
      x__file_move("#{@x_supervision_new_cluster_basedir}/.0x1.ini.0ring.tar",
                   "#{@x_ini_0ring_basedir}/")
      # downloading 0ring_ini_file
      x_0ring_uri = "https://raw.github.com/0xyl1s/0x1_supervision_templates/"+
        "master/#{@os}/0rings/#{@cluster_type}/0ring.#{@x_0ring_current}"
      x__http_download_and_save(x_0ring_uri, @x_ini_0ring_basedir)
      x_0ring_ini_file = "#{@x_ini_0ring_basedir}/0ring.#{@x_0ring_current}"
      abort "ERROR: x_0ring_ini file (#{x_0ring_ini_file}) can't be "+
        "downloaded from #{x_0ring_uri}" \
        unless x__is_a_file?(x_0ring_ini_file)
      puts "dowloaded x_0ring_ini_file (#{x_0ring_ini_file}, "+
        "from #{x_0ring_uri})"
    end

end

class ClusterIniPhase2 < ClusterIni

  def initialize(os, cluster_type, x_0ring_version)
    super
    require @x_ini_0ring_data_filepath
    # TODO: x_log_prefix time is fixed...
    @x_log_prefix = "<<<[0x1.0ring_ini #{X_MACHINE_HOSTNAME}."+
      "#{X_ENTITY_DOMAIN} #{x__datetime_sec}]>>>"
    dispatch_ini_0ring_data
    abort "ERROR: provided os info (#{X_MACHINE_OS}) is not compatible with "+
      "this install script (developped for #{@os})" unless @os == X_MACHINE_OS
    puts "XDEBUG: provided os info (#{X_MACHINE_OS}) is compatible with this "+
      "install script (developped for #{@os})"
    certificates_create
    x__file_save_nl(x__datetime_sec, "#{@x_ini_0ring_logsdir}/"+
                    "x.cluster_ini_0ring.#{@x_0ring_current}.phase2.done")
    remote_execute
  end

  def dispatch_ini_0ring_data()
    imported_ini_0ring_data = {}
    imported_ini_0ring_data[:x_machine_os] = {
      :import_value => X_MACHINE_OS,
      :dummy_text_replace => '@@_0x1_machine_os_@@',
      :file_relative_path => 'dispatch/system/00data/machine.os'
    }
    imported_ini_0ring_data[:x_machine_hostname] = {
      :import_value => X_MACHINE_HOSTNAME,
      :dummy_text_replace => '@@_0x1_machine_hostname_@@',
      :file_relative_path => 'dispatch/system/00data/machine.hostname'
    }
    imported_ini_0ring_data[:x_machine_ssh_port] = {
      :import_value => X_MACHINE_SSH_PORT,
      :dummy_text_replace => '@@_0x1_machine_ssh_port_@@',
      :file_relative_path => 'dispatch/system/00data/machine.ssh_port'
    }
    imported_ini_0ring_data[:x_entity_domain] = {
      :import_value => X_ENTITY_DOMAIN,
      :dummy_text_replace => '@@_0x1_entity_domain_@@',
      :file_relative_path => 'dispatch/system/00data/entity.domain'
    }
    imported_ini_0ring_data[:x_root_name] = {
      :import_value => X_ROOT_NAME,
      :dummy_text_replace => '@@_0x1_root_name_@@',
      :file_relative_path => 'dispatch/root/00data/user.name'
    }
    imported_ini_0ring_data[:x_root_email] = {
      :import_value => X_ROOT_EMAIL,
      :dummy_text_replace => '@@_0x1_root_email_@@',
      :file_relative_path => 'dispatch/root/00data/user.email'
    }
    imported_ini_0ring_data[:x_root_password] = {
      :import_value => X_ROOT_PASSWORD,
      :dummy_text_replace => '@@_0x1_root_password_@@',
      :file_relative_path => 'dispatch/root/00data/user.password'
    }
    imported_ini_0ring_data[:x_root_mainuser_name] = {
      :import_value => X_MAINUSER_NAME,
      :dummy_text_replace => '@@_0x1_mainuser_name_@@',
      :file_relative_path => 'dispatch/root/00data/mainuser.name'
    }
    imported_ini_0ring_data[:x_mainuser_name] = {
      :import_value => X_MAINUSER_NAME,
      :dummy_text_replace => '@@_0x1_mainuser_name_@@',
      :file_relative_path => 'dispatch/mainuser/00data/user.name'
    }
    imported_ini_0ring_data[:x_mainuser_uid] = {
      :import_value => X_MAINUSER_UID,
      :dummy_text_replace => '@@_0x1_mainuser_uid_@@',
      :file_relative_path => 'dispatch/mainuser/00data/user.uid'
    }
    imported_ini_0ring_data[:x_mainuser_gid] = {
      :import_value => X_MAINUSER_GID,
      :dummy_text_replace => '@@_0x1_mainuser_gid_@@',
      :file_relative_path => 'dispatch/mainuser/00data/user.gid'
    }
    imported_ini_0ring_data[:x_mainuser_email] = {
      :import_value => X_MAINUSER_EMAIL,
      :dummy_text_replace => '@@_0x1_mainuser_email_@@',
      :file_relative_path => 'dispatch/mainuser/00data/user.email'
    }
    imported_ini_0ring_data[:x_mainuser_password] = {
      :import_value => X_MAINUSER_PASSWORD,
      :dummy_text_replace => '@@_0x1_mainuser_password_@@',
      :file_relative_path => 'dispatch/mainuser/00data/user.password'
    }
    imported_ini_0ring_data[:x_mainuser_authorized_keys] = {
      :import_value => X_MAINUSER_AUTHORIZED_KEYS,
      :dummy_text_replace => '@@_0x1_mainuser_authorized_keys_@@',
      :file_relative_path => 'dispatch/mainuser/00certificates/authorized_keys'
    }

    imported_ini_0ring_data.each_pair do |ini_0ring, x_0ring_data|
      import_value = x_0ring_data[:import_value]
      dummy_text_replace = x_0ring_data[:dummy_text_replace]

      file_relative_path = x_0ring_data[:file_relative_path]
      file_full_path = File.join(@x_ini_0ring_basedir, file_relative_path)
      unless x__is_a_file?(file_full_path)
        abort "ERROR: can't access file #{file_full_path}" 
      end
      file_original_content = x__file_read(file_full_path)
      text_replace_regex = Regexp.new("#{dummy_text_replace.chomp}")
      new_content = file_original_content.gsub!(text_replace_regex,
                                                import_value)
      x__file_overwrite(new_content, file_full_path)
      file_new_content = x__file_read(file_full_path)
    end

  end

  def certificates_create()
    root_00certificates_ini_0ring_path = \
      "#{@x_ini_0ring_basedir}/dispatch/root/00certificates"
    mainuser_00certificates_ini_0ring_path = \
      "#{@x_ini_0ring_basedir}/dispatch/mainuser/00certificates"
    system "cd #{root_00certificates_ini_0ring_path} ; "+
      "echo '#{@x_log_prefix} generating root default ssh certificate "+
      "#{X_ROOT_SSH_DEFCERT_PASSCODE}' ; "+
      "x.certificate_create ./ #{X_MACHINE_HOSTNAME}_#{X_ROOT_NAME}_v1 "+
      "#{X_ROOT_SSH_DEFCERT_PASSCODE} -c"
    system "cd #{mainuser_00certificates_ini_0ring_path} ; echo "+
      "'#{@x_log_prefix} generating mainuser default ssh certificate "+
      "#{X_MAINUSER_SSH_DEFCERT_PASSCODE}' ; x.certificate_create ./ "+
      "#{X_MACHINE_HOSTNAME}_#{X_MAINUSER_NAME}_v1 "+
      "#{X_MAINUSER_SSH_DEFCERT_PASSCODE} -c"
  end

  def remote_execute()
    xdebug = true
    x_sup_ssh_pubkey_dummy = "@@_0x1_sup_ssh_pubkey_@@"
    ssh_command_initial_authorized_keys = x__content_replace(\
      RAW_SSH_COMMAND_INITIAL_AUTHORIZED_KEYS, x_sup_ssh_pubkey_dummy, \
      @xsup_ssh_pub_key)
    transfert_sup_ssh_pubkey_command = "echo \'"+
      "#{ssh_command_initial_authorized_keys}\' | ssh -p"+
      "#{X_MACHINE_TEMP_SSH_PORT} root@#{X_MACHINE_TEMP_IP} bash"
    puts transfert_sup_ssh_pubkey_command
    puts "#{@x_log_prefix} transfering Supervision user's ssh pubkey"
    abort "ERROR running #{transfert_sup_ssh_pubkey_command}" \
      unless system transfert_sup_ssh_pubkey_command
    until @rsync_command_executed
      rsync_command = "rsync -avh --no-o --no-g --stats --progress "+
        " --rsh='ssh -p#{X_MACHINE_TEMP_SSH_PORT}' #{@x_ini_0ring_basedir}/ "+
        "root@#{X_MACHINE_TEMP_IP}:/root/#{@x_ini_0ring_dir}/"
      if x__service_online?(X_MACHINE_TEMP_IP, X_MACHINE_TEMP_SSH_PORT)
        puts "#{@x_log_prefix} command: #{rsync_command}"
        @rsync_command_executed = true if system rsync_command
      else
        puts "#{@x_log_prefix} checking ip/port "+
          "#{X_MACHINE_TEMP_IP}/#{X_MACHINE_TEMP_SSH_PORT}: UNAVAILABLE"
      end
    end

    # launching remote phase_system
    ssh_root_temp_command = "ssh -p#{X_MACHINE_TEMP_SSH_PORT} "+
      "-o ConnectTimeout=15 root@#{X_MACHINE_TEMP_IP}"
    terminal_0ring_ini_ssh_root_phases_command = "urxvt -e "+
      "#{ssh_root_temp_command} bash /root/#{@x_ini_0ring_dir}/0ring"+
      ".#{@x_0ring_current} &"
    until @x_0ring_ini_ssh_root_phases_command_executed
      if x__service_online?(X_MACHINE_TEMP_IP, X_MACHINE_TEMP_SSH_PORT)
        puts "#{@x_log_prefix} starting remote phase_system installation: \n"+
          "#{terminal_0ring_ini_ssh_root_phases_command}\n\n"
        puts "#{@x_log_prefix} to follow the main live log, run: \n"+
          "#{ssh_root_temp_command} tail -f '\~/.0x1.ini.0ring/logs/0x1.ini."+
          "system.0ring'\n\n"
        #test_command = "#{ssh_root_temp_command} ls -al /root \\; sleep 5"
        #system "urxvt -e #{test_command}"
        abort "ERROR running command:\n"+
          "#{terminal_0ring_ini_ssh_root_phases_command}" \
          unless system "#{terminal_0ring_ini_ssh_root_phases_command}"
        @x_0ring_ini_ssh_root_phases_command_executed = true
      else
        puts "#{@x_log_prefix}>> checking ip/port #{X_MACHINE_TEMP_IP}/"+
          "#{X_MACHINE_TEMP_SSH_PORT}: UNAVAILABLE"
      end
      sleep 20
    end

    # launching remote phase_root
    remote_check_phase_system_done_0ring_command = "#{ssh_root_temp_command}"+
      " 'cat /root/#{@x_ini_0ring_dir}/logs/0x1.ini.system.done.0ring"+
      " 2>/dev/null'"
    until defined? @remote_check_phase_system_done_0ring_checked
      break if defined? @remote_check_system_ready_checked
      puts "XDEBUG>>> defined? @remote_check_system_ready_checked => "+
        "#{(defined? @remote_check_system_ready_checked).class}" if xdebug
      if x__service_online?(X_MACHINE_TEMP_IP, X_MACHINE_TEMP_SSH_PORT)
        puts "#{@x_log_prefix}checking "+
          "remote_check_phase_system_done_0ring_command"
        puts "#{remote_check_phase_system_done_0ring_command}" if xdebug
        remote_check_phase_system_done_0ring = \
          %x"#{remote_check_phase_system_done_0ring_command}"
        if remote_check_phase_system_done_0ring.chomp == 'done'
          puts "\n\n#{@x_log_prefix} 0ring_ini_phase_system: DONE\n"
          puts "#{@x_log_prefix} starting root_phase: \n"+
            "#{terminal_0ring_ini_ssh_root_phases_command}\n\n"
          puts "#{@x_log_prefix} to follow the main live log, run: \n"+
            "#{ssh_root_temp_command} tail -f "+
            "'\~/.0x1.ini.0ring/logs/0x1.ini.root_phase2.0ring'\n\n"
          abort "ERROR running command:\n"+
            "#{terminal_0ring_ini_ssh_root_phases_command}" \
            unless system "#{terminal_0ring_ini_ssh_root_phases_command}"
          @remote_check_phase_system_done_0ring_checked = true
        end
      else
        puts "#{@x_log_prefix} checking ip/port #{X_MACHINE_TEMP_IP}/"+
          "#{X_MACHINE_TEMP_SSH_PORT}: UNAVAILABLE"
      end
      sleep 20
      remote_checking_system_ready(false)
    end
    until defined? @remote_check_system_ready_checked
      remote_checking_system_ready
      sleep 20
    end
    puts "FIN ?"
      end

    def remote_checking_system_ready(verbose=true)
      xdebug = true
      # checking system_ready
      ssh_mainuser_command = "ssh -p#{X_MACHINE_SSH_PORT} -o "+
        "PasswordAuthentication=no -o ConnectTimeout=5 "+
        "#{X_MAINUSER_NAME}@#{X_MACHINE_TEMP_IP}"
      remote_check_system_ready_command = "#{ssh_mainuser_command} 'cat "+
        "/home/#{X_MAINUSER_NAME}/.0x1.ini_user/0x1.ini.system.ready.0ring"+
        " 2>/dev/null'"
      if verbose
        puts "#{@x_log_prefix} checking remote_check_system_ready_command"
      end
      if verbose and xdebug
        puts "#{remote_check_system_ready_command}" 
      end
      if x__service_online?(X_MACHINE_TEMP_IP, X_MACHINE_SSH_PORT)
        remote_check_system_ready = %x"#{remote_check_system_ready_command}"
        if remote_check_system_ready == 'ready'
          @remote_check_system_ready_checked = true
        end
      else
        if verbose and not x__service_online?(X_MACHINE_TEMP_IP, \
                                              X_MACHINE_TEMP_SSH_PORT)
          puts "#{@x_log_prefix} checking ip/port #{X_MACHINE_TEMP_IP}/"+
            "#{X_MACHINE_SSH_PORT}: UNAVAILABLE"
        end
      end
    end

  end

end end end


        # ____________________________________________________________________
        # >>>>>  projet epiculture/ec1   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#{{{
        # Sources, Infos & Contact : http://www.epiculture.org
        # Author: Pierre-Maël Crétinon
        # License: GNU GPLv3 ( www.epiculture.org/ec1/LICENSE )
        # Copyright: 2010-2012 Pierre-Maël Crétinon
        # Sponsor: studio Helianova - http://studio.helianova.com
        # ――――――――――――――――――――――――――――――――――――――#}}}
        # vim: ft=ruby
