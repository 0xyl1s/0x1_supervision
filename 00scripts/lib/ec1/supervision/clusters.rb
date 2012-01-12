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

class ClusterIni
require 'ec1/lib/toolkit/standard.rb'
include Ec1::Lib::Toolkit::Standard
require 'ec1/lib/toolkit/online.rb'
include Ec1::Lib::Toolkit::Online

def initialize(os, cluster_type, ering_version)
  @ec1_supervision_new_cluster_basedir = File.expand_path("~/.ec1.sup/cluster.new")
  @ec1_ini_ering_basedir = "#{@ec1_supervision_new_cluster_basedir}/.ec1.ini.ering"
  @ec1_ini_ering_data_filepath = "#{@ec1_ini_ering_basedir}/.ec1.ini.ering.data.rb"
end

end

class ClusterIniPhase1 < ClusterIni

def initialize(os, cluster_type, ering_version)
  super
  abort "ERROR: invalid os type (#{os}" unless valid_os?(os)
  @os = os
  abort "ERROR: invalid cluster_type (#{cluster_type}" unless valid_os?(os)
  @cluster_type = cluster_type if valid_cluster_type?(cluster_type)
  @cluster_type_shortname = cluster_type_shortname(@cluster_type)
  abort "ERROR: when starting new cluster installation, ec1_supervision_new_cluster_basedir should be empty (#{@ec1_supervision_new_cluster_basedir})" unless e__dir_is_empty?(@ec1_supervision_new_cluster_basedir)
  @ering_version = ering_version
  download_raw_install_ini_dir
  puts "\n\nec1.cluster_ini_phase1 completed. When datafile is filled #{@ec1_ini_ering_data_filepath}, please run\n\ne.cluster_ini_ering.cc01.phase2\n\n"
  %x"e #{@ec1_ini_ering_data_filepath}"
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
  ering_uri = "https://raw.github.com/epiculture/ec1_supervision_templates/master/#{@os}/erings/#{@cluster_type}/ering.#{@cluster_type_shortname}#{@ering_version}"
  e__http_download_and_save(ering_uri, @ec1_ini_ering_basedir)
  ering_ini_file = "#{@ec1_ini_ering_basedir}/ering.#{@cluster_type_shortname}#{@ering_version}"
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
  require @ec1_ini_ering_data_filepath
  dispatch_ini_ering_data
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
  imported_ini_ering_data.each_pair do |ini_ering, ering_data|
    import_value = ering_data[:import_value]
    dummy_text_replace = ering_data[:dummy_text_replace]
    puts "dummy_text_replace = #{dummy_text_replace}"
    file_relative_path = ering_data[:file_relative_path]
    file_full_path = File.join(@ec1_ini_ering_basedir, file_relative_path)
    abort "ERROR: can't access file #{file_full_path}" unless e__is_a_file?(file_full_path)
    file_original_content = e__file_read(file_full_path)
    puts "file_original_content = #{file_original_content}"
    puts "import_value = #{import_value}"
    new_content = file_original_content.sub!(/#{dummy_text_replace}/, import_value)
    #puts "file #{file_full_path} => replacing dummy content #{dummy_text_replace} by new content #{import_value}"
    puts "new_content = #{new_content}"
    puts "file_full_path = #{file_full_path}"
    e__file_overwrite(new_content, file_full_path)
    file_new_content = e__file_read(file_full_path)
    puts "file_new_content = #{file_new_content}"
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
