# encoding: utf-8
# tested with ruby 1.9.2

module X module Admins module Utils module Machines
require_relative '0x1_lib.helper.rb'

class Groups
def initialize()
  x__load_modules([:standard])
  @machine_group_file = '/etc/group'
  @machine_groups_raw = x__file_readlines(@machine_group_file)
  @machine_group_0x1_file = '/root/.0x1/00data/groups'
  @machine_groups_0x1_raw = x__file_readlines(@machine_group_0x1_file)
end

def info_machine_group(machine_group_name_raw, info_level_raw=:summary)
  machine_group_name = machine_group_name_raw.to_s
  info_level = info_level_raw.to_sym
  abort "unknown group: #{machine_group_name}" unless check_machine_group(machine_group_name)
  group_reg = /^#{machine_group_name}:/
  group_line = []
  @machine_groups_raw.each do |machine_group_line|
    group_line << machine_group_line if machine_group_line =~ group_reg
  end
  group_name, group_x, group_id, group_users = group_line.join.split(":")
  case info_level
  when :summary
    puts "group_name = #{group_name}\ngroup_x = #{group_x}\ngroup_id = #{group_id}\ngroup_users = #{group_users}"
  when :name
    puts group_name
  when :x
    puts group_x
  when :id
    puts group_id
  when :users
    puts group_users
  end
end

def check_machine_group(machine_group_name)
  @machine_groups_names = @machine_groups_raw.map {|group_infos_raw| group_infos_raw.split(":").first}
  @machine_groups_names.include?(machine_group_name)
end

def info_machine_groups_user_membership(machine_user)
  #TODO: create a method check_machine_user() to check valid users on /etc/passwd
  #abort "invalid user #{machine_user}" unless check_machine_user(machine_user)
  machine_groups_user_membership = []
  @machine_groups_raw.each do |machine_group_line|
    group_name, group_x, group_id, group_users_raw = machine_group_line.split(":")
    group_users = []
    if group_users_raw =~ /,/ 
      group_users_raw.split(',').each {|group| group_users << group}
    else
      group_users << group_users_raw
    end
    group_users.each {|group| machine_groups_user_membership << group_name if group.include?(machine_user)}
  end
  puts machine_groups_user_membership.sort
end

def check_machine_group_id(machine_group_id)
end

def machine_group_add(new_machine_group, new_machine_id)
end

def machine_group_add_from_0x1_file
end
end

end end end end


# Project infos >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>># {{{
# Project: Epiculture
# Author: Pierre-Mael Cretinon
# Email: projects2011@3eclipses.com
# coding style: 0.0.2
# License: GNU GPLv3
#
# Notes:
#
# License details:
# <copyright/copyleft>
# Copyright 2010-2011 (c) Pierre-Mael CRETINON <copyleft@pierremael.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# </copyright/copyleft>
# Project infos <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<# }}}
#vim: foldmethod=marker
