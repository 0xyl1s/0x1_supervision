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
  puts "\n\nec1.cluster_ini_phase1 completed. When datafile completed\n#{@ec1_ini_ering_basedir}/.ec1.ini.ering.data\n, please run\n\n"
end


private

def download_raw_install_ini_dir()
  ini_dir_archive_uri = "https://raw.github.com/epiculture/ec1_supervision_templates/master/#{@os}/erings/#{@cluster_type}/ini_ering_templates/variation_01/.ec1.ini.ering.tar"
  e__http_download_and_save(ini_dir_archive_uri, @ec1_supervision_new_cluster_basedir)
  system "cd #{@ec1_supervision_new_cluster_basedir} ; tar xvf ./.ec1.ini.ering.tar"
  abort "ERROR: can't access @ec1_ini_ering_basedir (#{@ec1_ini_ering_basedir})" unless e__is_a_dir?(@ec1_ini_ering_basedir)
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
