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

# TODO: merge phases 1 and 2 classes into main ClusterIni class
class ClusterIni
require 'ec1/lib/toolkit/standard.rb'
include Ec1::Lib::Toolkit::Standard
require 'ec1/lib/toolkit/online.rb'
include Ec1::Lib::Toolkit::Online

def initialize(os, cluster_type, ering_version)
  # TODO: convert to ec1_lib method e__user_homedir
  # TODO: check availability of the mandatory sshpass program
  ec1_user_homedir = File.expand_path("~")
  @ec1_supervision_new_cluster_basedir = "#{ec1_user_homedir}/.ec1.sup/cluster.new"
  @ec1_ini_ering_dir = ".ec1.ini.ering"
  @ec1_ini_ering_basedir = "#{@ec1_supervision_new_cluster_basedir}/#{@ec1_ini_ering_dir}"
  @ec1_ini_ering_logsdir = "#{@ec1_supervision_new_cluster_basedir}/.ec1.ini.ering/logs"
  @ec1_ini_ering_data_filepath = "#{@ec1_ini_ering_basedir}/.ec1.ini.ering.data.rb"
end

end

class ClusterIniPhase1 < ClusterIni

def initialize(os, cluster_type, ering_version)
  super
  e__mkdir_p(@ec1_supervision_new_cluster_basedir) unless e__is_a_dir?(@ec1_supervision_new_cluster_basedir)
  abort "ERROR: can't access neither create supervision basedir (#{@ec1_supervision_new_cluster_basedir})" unless e__is_a_dir?(@ec1_supervision_new_cluster_basedir)
  abort "ERROR: when starting new cluster installation, ec1_supervision_new_cluster_basedir should be empty (#{@ec1_supervision_new_cluster_basedir})" unless e__dir_is_empty?(@ec1_supervision_new_cluster_basedir)
  abort "ERROR: invalid os type (#{os}" unless valid_os?(os)
  @os = os
  abort "ERROR: invalid cluster_type (#{cluster_type}" unless valid_os?(os)
  @cluster_type = cluster_type if valid_cluster_type?(cluster_type)
  @cluster_type_shortname = cluster_type_shortname(@cluster_type)
  @ering_version = ering_version
  @ering_current = "#{@cluster_type_shortname}#{@ering_version}"
  download_raw_install_ini_dir
  puts "\n\nec1.cluster_ini_phase1 completed. When datafile is filled #{@ec1_ini_ering_data_filepath}, please run\n\ne.cluster_ini_ering.#{@ering_current}.phase2\n\n"
  %x"e #{@ec1_ini_ering_data_filepath}"
  e__file_save_nl(e__datetime_sec, "#{@ec1_ini_ering_logsdir}/e.cluster_ini_ering.#{@ering_current}.phase1.done")
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

class ClusterIniPhase2 < ClusterIni

def initialize(os, cluster_type, ering_version)
  super
  abort "ERROR: can't process ini phase1 done log file" unless e__is_a_file?("#{@ec1_ini_ering_logsdir}/e.cluster_ini_ering.#{@ering_current}.phase1.done")
  require @ec1_ini_ering_data_filepath
  dispatch_ini_ering_data
  certificates_create
  e__file_save_nl(e__datetime_sec, "#{@ec1_ini_ering_logsdir}/e.cluster_ini_ering.#{@ering_current}.phase2.done")
  project_cluster_ini_dir
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
  system "cd #{root_00certificates_ini_ering_path} ; echo 'ec1>>> generating root default ssh certificate' ; e.certificate_create ./ #{EC1_MACHINE_HOSTNAME}_#{EC1_ROOT_NAME}_v1 #{EC1_ROOT_SSH_DEFCERT_PASSCODE} -c"
  system "cd #{mainuser_00certificates_ini_ering_path} ; echo 'ec1>>> generating mainuser default ssh certificate' ; e.certificate_create ./ #{EC1_MACHINE_HOSTNAME}_#{EC1_MAINUSER_NAME}_v1 #{EC1_MAINUSER_SSH_DEFCERT_PASSCODE} -c"
end

def project_cluster_ini_dir()
  rsync_command = "rsync -avh --no-o --no-g --stats --progress #{@ec1_ini_ering_basedir}/ nc:/root/#{@ec1_ini_ering_dir}/"
  puts rsync_command
  system rsync_command
end

def remote_execute()
  # TODO: need to get system call pid to kill stucked ssh connection tries
  # launching remote phase_system
  remote_execute_command = "sshpass -p #{EC1_ROOT_TEMPPASS} e.. nc 'bash /root/#{@ec1_ini_ering_dir}/ering.#{@ering_current}' &"
  puts "#{e__datetime_sec} >>> starting remote phase_system (#{remote_execute_command})"
  system remote_execute_command
  remote_check_phase_system_done_ering = "sshpass -p #{EC1_ROOT_TEMPPASS} ssh nc 'cat /root/#{@ec1_ini_ering_dir}/logs/ec1.ini.system.done.ering"
  until remote_check_phase_system_done_ering == 'done'
    puts "#{e__datetime_sec} >>> checking remote_check_phase_system_done_ering (#{remote_check_phase_system_done_ering})"
    system remote_check_phase_system_done_ering
    sleep 30
  end
  # launching remote phase_root
  puts "#{e__datetime_sec} >>> starting root_phase2 (#{remote_execute_command})"
  system remote_execute_command
  # checking system_ready
  remote_check_system_ready_ering = "sshpass -p #{EC1_ROOT_TEMPPASS} ssh nc 'cat /home/#{EC1_MAINUSER_NAME}/.ec1.ini_user/ec1.ini.system.ready.ering"
  until remote_check_system_ready_ering == 'ready'
    puts "#{e__datetime_sec} >>> checking remote_check_system_ready_ering (#{remote_check_system_ready_ering})"
    system remote_check_system_ready_ering
    sleep 30
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
