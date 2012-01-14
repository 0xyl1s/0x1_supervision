# encoding: utf-8
# tested with ruby 1.9.3

module Ec1 module Supervision module Clusters

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


RAW_SSH_COMMAND_INITIAL_AUTHORIZED_KEYS = <<EC1HEREDOC
#!/usr/bin/env bash
sup_ssh_pubkey="@@_ec1_sup_ssh_pubkey_@@"

user_home_dir=$(cd ~ ; pwd)
user_ssh_dir="${user_home_dir}/.ssh"
echo "${user_ssh_dir}"
if [[ -d "${user_ssh_dir}" ]]
then
    echo "${user_ssh_dir}"
    mv "${user_ssh_dir}" "${user_ssh_dir}.ini"
    echo "moving initial ssh dir"
fi
mkdir ${user_ssh_dir}
chmod 700 ${user_ssh_dir}
user_authorized_keys_file="${user_ssh_dir}/authorized_keys"
echo ${sup_ssh_pubkey} > ${user_authorized_keys_file}
chmod 600 ${user_authorized_keys_file}
ls -al ${user_ssh_dir}
# vim: ft=sh
EC1HEREDOC


# TODO: merge phases 1 and 2 classes into main ClusterIni class
class ClusterIni
require 'ec1/lib/toolkit/standard.rb'
include Ec1::Lib::Toolkit::Standard
require 'ec1/lib/toolkit/online.rb'
include Ec1::Lib::Toolkit::Online

def initialize(os, cluster_type, ering_version)
  @os = os
  abort "ERROR: invalid cluster_type (#{cluster_type}" unless valid_os?(os)
  @cluster_type = cluster_type if valid_cluster_type?(cluster_type)
  @cluster_type_shortname = cluster_type_shortname(@cluster_type)
  @ering_version = ering_version
  @ering_current = "#{@cluster_type_shortname}#{@ering_version}"
  @ec1_user_homedir = e__user_homedir
  ec1sup_ssh_pub_key_file = "#{@ec1_user_homedir}/.ssh/id_rsa.pub"
  abort "EC1ERROR: can't access ec1sup_ssh_pub_key_file (#{ec1sup_ssh_pub_key_file})" unless e__is_a_file?(ec1sup_ssh_pub_key_file) or e__is_a_symlink?(ec1sup_ssh_pub_key_file)
  @ec1sup_ssh_pub_key = e__file_read_chomp(ec1sup_ssh_pub_key_file)
  @ec1_supervision_new_cluster_basedir = "#{@ec1_user_homedir}/.ec1.sup/cluster.new"
  @ec1_ini_ering_dir = ".ec1.ini.ering"
  @ec1_ini_ering_basedir = "#{@ec1_supervision_new_cluster_basedir}/#{@ec1_ini_ering_dir}"
  @ec1_ini_ering_logsdir = "#{@ec1_supervision_new_cluster_basedir}/.ec1.ini.ering/logs"
  @ec1_ini_ering_data_filepath = "#{@ec1_ini_ering_basedir}/.ec1.ini.ering.data.rb"
end

def valid_os?(os)
  e__array_value_exist?(OSES, os)
end

def valid_cluster_type?(cluster_type)
  e__array_value_exist?(CLUSTER_TYPES, cluster_type)
end

def cluster_type_shortname(cluster_type)
  CLUSTER_TYPE_SHORTNAMES[cluster_type]
end

end

class ClusterIniPhase1 < ClusterIni

def initialize(os, cluster_type, ering_version)
  super
  e__mkdir_p(@ec1_supervision_new_cluster_basedir) unless e__is_a_dir?(@ec1_supervision_new_cluster_basedir)
  abort "ERROR: can't access neither create supervision basedir (#{@ec1_supervision_new_cluster_basedir})" unless e__is_a_dir?(@ec1_supervision_new_cluster_basedir)
  abort "ERROR: when starting new cluster installation, ec1_supervision_new_cluster_basedir should be empty (#{@ec1_supervision_new_cluster_basedir})" unless e__dir_is_empty?(@ec1_supervision_new_cluster_basedir)
  abort "ERROR: invalid os type (#{os}" unless valid_os?(os)
  download_raw_install_ini_dir
  puts "\n\nec1.cluster_ini_phase1 completed. When datafile is filled #{@ec1_ini_ering_data_filepath}, please run again\n\ne.cluster_ini_ering.#{@ering_current}\n\n"
  %x"e #{@ec1_ini_ering_data_filepath}"
  ec1_ini_ering_phase1_done_file = "#{@ec1_ini_ering_logsdir}/e.cluster_ini_ering.#{@ering_current}.phase1.done"
  e__file_save_nl(e__datetime_sec, ec1_ini_ering_phase1_done_file)
  abort "ERROR: can't process ini phase1 done log file" unless e__is_a_file?(ec1_ini_ering_phase1_done_file)
  ClusterIniPhase2.new(@os, @cluster_type, @ering_version)
end


private

def download_raw_install_ini_dir()
  # dowloading raw ini dir archive
  ini_dir_archive_uri = "https://raw.github.com/epiculture/ec1_supervision_templates/master/#{@os}/erings/#{@cluster_type}/ini_ering_templates/variation_01/.ec1.ini.ering.tar"
  e__http_download_and_save(ini_dir_archive_uri, @ec1_supervision_new_cluster_basedir)
  # extracting ini dir tar archive
  %x"cd #{@ec1_supervision_new_cluster_basedir} ; tar xvf ./.ec1.ini.ering.tar"
  abort "ERROR: can't access @ec1_ini_ering_basedir (#{@ec1_ini_ering_basedir})" unless e__is_a_dir?(@ec1_ini_ering_basedir)
  e__file_move("#{@ec1_supervision_new_cluster_basedir}/.ec1.ini.ering.tar", "#{@ec1_ini_ering_basedir}/")
  # downloading ering_ini_file
  ering_uri = "https://raw.github.com/epiculture/ec1_supervision_templates/master/#{@os}/erings/#{@cluster_type}/ering.#{@ering_current}"
  e__http_download_and_save(ering_uri, @ec1_ini_ering_basedir)
  ering_ini_file = "#{@ec1_ini_ering_basedir}/ering.#{@ering_current}"
  abort "ERROR: ering_ini file (#{ering_ini_file}) can't be downloaded from #{ering_uri}" unless e__is_a_file?(ering_ini_file)
  puts "dowloaded ering_ini_file (#{ering_ini_file}, from #{ering_uri})"
end

end

class ClusterIniPhase2 < ClusterIni

def initialize(os, cluster_type, ering_version)
  super
  require @ec1_ini_ering_data_filepath
  @ec1_log_prefix = "<<<[ec1.ering_ini #{EC1_MACHINE_HOSTNAME}.#{EC1_ENTITY_DOMAIN} #{e__datetime_sec}]>>>"
  dispatch_ini_ering_data
  certificates_create
  e__file_save_nl(e__datetime_sec, "#{@ec1_ini_ering_logsdir}/e.cluster_ini_ering.#{@ering_current}.phase2.done")
  remote_execute
end

def dispatch_ini_ering_data()
  imported_ini_ering_data = {}
  imported_ini_ering_data[:ec1_machine_ssh_port] = {
                                                    :import_value => EC1_MACHINE_SSH_PORT,
                                                    :dummy_text_replace => '@@_ec1_machine_ssh_port_@@',
                                                    :file_relative_path => 'dispatch/system/00data/machine.ssh_port'
                                                    }
  imported_ini_ering_data[:ec1_entity_domain] = {
                                                    :import_value => EC1_ENTITY_DOMAIN,
                                                    :dummy_text_replace => '@@_ec1_entity_domain_@@',
                                                    :file_relative_path => 'dispatch/system/00data/entity.domain'
                                                    }

  imported_ini_ering_data[:ec1_machine_ssh_port] = {
                                                    :import_value => EC1_MACHINE_SSH_PORT,
                                                    :dummy_text_replace => '@@_ec1_machine_ssh_port_@@',
                                                    :file_relative_path => 'dispatch/system/00data/machine.ssh_port'
                                                    }
  imported_ini_ering_data[:ec1_entity_domain] = {
                                                    :import_value => EC1_ENTITY_DOMAIN,
                                                    :dummy_text_replace => '@@_ec1_entity_domain_@@',
                                                    :file_relative_path => 'dispatch/system/00data/entity.domain'
                                                    }
  imported_ini_ering_data[:ec1_machine_hostname] = {
                                                    :import_value => EC1_MACHINE_HOSTNAME,
                                                    :dummy_text_replace => '@@_ec1_machine_hostname_@@',
                                                    :file_relative_path => 'dispatch/system/00data/machine.hostname'
                                                   }
  imported_ini_ering_data[:ec1_root_name] = {
                                             :import_value => EC1_ROOT_NAME,
                                             :dummy_text_replace => '@@_ec1_root_name_@@',
                                             :file_relative_path => 'dispatch/root/00data/user.name'
                                            }
  imported_ini_ering_data[:ec1_root_email] = {
                                             :import_value => EC1_ROOT_EMAIL,
                                             :dummy_text_replace => '@@_ec1_root_email_@@',
                                             :file_relative_path => 'dispatch/root/00data/user.email'
                                            }
  imported_ini_ering_data[:ec1_root_password] = {
                                             :import_value => EC1_ROOT_PASSWORD,
                                             :dummy_text_replace => '@@_ec1_root_password_@@',
                                             :file_relative_path => 'dispatch/root/00data/user.password'
                                            }
  imported_ini_ering_data[:ec1_root_mainuser_name] = {
                                             :import_value => EC1_MAINUSER_NAME,
                                             :dummy_text_replace => '@@_ec1_mainuser_name_@@',
                                             :file_relative_path => 'dispatch/root/00data/mainuser.name'
                                            }
  imported_ini_ering_data[:ec1_mainuser_name] = {
                                             :import_value => EC1_MAINUSER_NAME,
                                             :dummy_text_replace => '@@_ec1_mainuser_name_@@',
                                             :file_relative_path => 'dispatch/mainuser/00data/user.name'
                                            }
  imported_ini_ering_data[:ec1_mainuser_uid] = {
                                             :import_value => EC1_MAINUSER_UID,
                                             :dummy_text_replace => '@@_ec1_mainuser_uid_@@',
                                             :file_relative_path => 'dispatch/mainuser/00data/user.uid'
                                            }
  imported_ini_ering_data[:ec1_mainuser_gid] = {
                                             :import_value => EC1_MAINUSER_GID,
                                             :dummy_text_replace => '@@_ec1_mainuser_gid_@@',
                                             :file_relative_path => 'dispatch/mainuser/00data/user.gid'
                                            }
  imported_ini_ering_data[:ec1_mainuser_email] = {
                                             :import_value => EC1_MAINUSER_EMAIL,
                                             :dummy_text_replace => '@@_ec1_mainuser_email_@@',
                                             :file_relative_path => 'dispatch/mainuser/00data/user.email'
                                            }
  imported_ini_ering_data[:ec1_mainuser_password] = {
                                             :import_value => EC1_MAINUSER_PASSWORD,
                                             :dummy_text_replace => '@@_ec1_mainuser_password_@@',
                                             :file_relative_path => 'dispatch/mainuser/00data/user.password'
                                            }
  imported_ini_ering_data[:ec1_mainuser_authorized_keys] = {
                                             :import_value => EC1_MAINUSER_AUTHORIZED_KEYS,
                                             :dummy_text_replace => '@@_ec1_mainuser_authorized_keys_@@',
                                             :file_relative_path => 'dispatch/mainuser/00certificates/authorized_keys'
                                            }

  imported_ini_ering_data.each_pair do |ini_ering, ering_data|
    import_value = ering_data[:import_value]
    dummy_text_replace = ering_data[:dummy_text_replace]

    file_relative_path = ering_data[:file_relative_path]
    file_full_path = File.join(@ec1_ini_ering_basedir, file_relative_path)
    abort "ERROR: can't access file #{file_full_path}" unless e__is_a_file?(file_full_path)
    file_original_content = e__file_read(file_full_path)
    text_replace_regex = Regexp.new("#{dummy_text_replace.chomp}")
    new_content = file_original_content.gsub!(text_replace_regex, import_value)
    e__file_overwrite(new_content, file_full_path)
    file_new_content = e__file_read(file_full_path)
  end

end

def certificates_create()
  root_00certificates_ini_ering_path = "#{@ec1_ini_ering_basedir}/dispatch/root/00certificates"
  mainuser_00certificates_ini_ering_path = "#{@ec1_ini_ering_basedir}/dispatch/mainuser/00certificates"
  system "cd #{root_00certificates_ini_ering_path} ; echo '#{@ec1_log_prefix} generating root default ssh certificate #{EC1_ROOT_SSH_DEFCERT_PASSCODE}' ; e.certificate_create ./ #{EC1_MACHINE_HOSTNAME}_#{EC1_ROOT_NAME}_v1 #{EC1_ROOT_SSH_DEFCERT_PASSCODE} -c"
  system "cd #{mainuser_00certificates_ini_ering_path} ; echo '#{@ec1_log_prefix} generating mainuser default ssh certificate #{EC1_MAINUSER_SSH_DEFCERT_PASSCODE}' ; e.certificate_create ./ #{EC1_MACHINE_HOSTNAME}_#{EC1_MAINUSER_NAME}_v1 #{EC1_MAINUSER_SSH_DEFCERT_PASSCODE} -c"
end

# TODO: move to ec1_lib
def e__content_replace(s_content, s_search_regex, s_replace_value)
  s_content.sub(/#{s_search_regex}/, s_replace_value)
end

def remote_execute()
  ec1debug = true
  ec1_sup_ssh_pubkey_dummy = "@@_ec1_sup_ssh_pubkey_@@"
  ssh_command_initial_authorized_keys = e__content_replace(RAW_SSH_COMMAND_INITIAL_AUTHORIZED_KEYS, ec1_sup_ssh_pubkey_dummy, @ec1sup_ssh_pub_key)
  transfert_sup_ssh_pubkey_command = "echo \"#{ssh_command_initial_authorized_keys}\" | ssh -p#{EC1_MACHINE_TEMP_SSH_PORT} root@#{EC1_MACHINE_TEMP_IP} bash"
  puts transfert_sup_ssh_pubkey_command
  abort
  until @rsync_command_executed
    rsync_command = "rsync -avh --no-o --no-g --stats --progress --rsh='ssh -p#{EC1_MACHINE_TEMP_SSH_PORT}' #{@ec1_ini_ering_basedir}/ root@#{EC1_MACHINE_TEMP_IP}:/root/#{@ec1_ini_ering_dir}/"
    if e__service_online?(EC1_MACHINE_TEMP_IP, EC1_MACHINE_TEMP_SSH_PORT)
      puts "#{@ec1_log_prefix} command: #{rsync_command}"
      @rsync_command_executed = true if system rsync_command
    else
      puts "#{@ec1_log_prefix} checking ip/port #{EC1_MACHINE_TEMP_IP}/#{EC1_MACHINE_TEMP_SSH_PORT}: UNAVAILABLE1"
    end
  end

  # launching remote phase_system
  ssh_root_temp_command = "ssh -p#{EC1_MACHINE_TEMP_SSH_PORT} -o PasswordAuthentication=no -o ConnectTimeout=5 root@#{EC1_MACHINE_TEMP_IP}"
  ssh_root_temp_command_interactive = "ssh -p#{EC1_MACHINE_TEMP_SSH_PORT} -o ConnectTimeout=15 root@#{EC1_MACHINE_TEMP_IP}"
  ering_ini_ssh_root_phases_command = "#{ssh_root_temp_command_interactive} 'bash /root/#{@ec1_ini_ering_dir}/ering.#{@ering_current}'"
  until @ering_ini_ssh_root_phases_command_executed
    if e__service_online?(EC1_MACHINE_TEMP_IP, EC1_MACHINE_TEMP_SSH_PORT)
      puts "#{@ec1_log_prefix} starting remote phase_system installation: please run\n\n#{ering_ini_ssh_root_phases_command}\n\n"
      @ering_ini_ssh_root_phases_command_executed = true
    else
      puts "#{@ec1_log_prefix}>> checking ip/port #{EC1_MACHINE_TEMP_IP}/#{EC1_MACHINE_TEMP_SSH_PORT}: UNAVAILABLE2"
    end
    sleep 20
  end

  # launching remote phase_root
  remote_check_phase_system_done_ering_command = "#{ssh_root_temp_command} 'cat /root/#{@ec1_ini_ering_dir}/logs/ec1.ini.system.done.ering 2>/dev/null'"
  until defined? @remote_check_phase_system_done_ering_checked
    break if defined? @remote_check_system_ready_checked
    puts "EC1DEBUG>>> defined? @remote_check_system_ready_checked => #{(defined? @remote_check_system_ready_checked).class}" if ec1debug
    if e__service_online?(EC1_MACHINE_TEMP_IP, EC1_MACHINE_TEMP_SSH_PORT)
      puts "#{@ec1_log_prefix}checking remote_check_phase_system_done_ering_command"
      puts "#{remote_check_phase_system_done_ering_command}" if ec1debug
      remote_check_phase_system_done_ering = %x"#{remote_check_phase_system_done_ering_command}"
      if remote_check_phase_system_done_ering.chomp == 'done'
        puts "\n\n#{@ec1_log_prefix} ering_ini_phase_system: DONE\n"
        puts "#{@ec1_log_prefix} starting root_phase: please run >>>>>\n\n#{ering_ini_ssh_root_phases_command}\n\n"
        @remote_check_phase_system_done_ering_checked = true
      end
    else
      puts "#{@ec1_log_prefix} checking ip/port #{EC1_MACHINE_TEMP_IP}/#{EC1_MACHINE_TEMP_SSH_PORT}: UNAVAILABLE3"
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
  ec1debug = true
  # checking system_ready
  ssh_mainuser_command = "ssh -p#{EC1_MACHINE_SSH_PORT} -o PasswordAuthentication=no -o ConnectTimeout=5 #{EC1_MAINUSER_NAME}@#{EC1_MACHINE_TEMP_IP}"
  remote_check_system_ready_command = "#{ssh_mainuser_command} 'cat /home/#{EC1_MAINUSER_NAME}/.ec1.ini_user/ec1.ini.system.ready.ering 2>/dev/null'"
  puts "#{@ec1_log_prefix} checking remote_check_system_ready_command" if verbose
  puts "#{remote_check_system_ready_command}" if verbose and ec1debug
  if e__service_online?(EC1_MACHINE_TEMP_IP, EC1_MACHINE_SSH_PORT) then
    remote_check_system_ready = %x"#{remote_check_system_ready_command}"
    if remote_check_system_ready == 'ready'
      @remote_check_system_ready_checked = true
    end
  else
    unless e__service_online?(EC1_MACHINE_TEMP_IP, EC1_MACHINE_TEMP_SSH_PORT)
      puts "#{@ec1_log_prefix} checking ip/port #{EC1_MACHINE_TEMP_IP}/#{EC1_MACHINE_SSH_PORT}: UNAVAILABLE4" if verbose
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
