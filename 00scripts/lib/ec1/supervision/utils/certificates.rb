# encoding: utf-8
# tested with ruby 1.9.3

module Ec1 module Supervision module Utils module Security

class Certificates
require 'ec1/lib/toolkit/standard.rb'
include Ec1::Lib::Toolkit::Standard

def create(path, name, passphrase_code, default_cert_file_option, passphrase=nil)
  abort "path unavailable: #{path}" unless e__is_a_dir?(path)
  certificate_path = File.join(path, name)
  abort "certificate file exists already: #{certificate_path}" if e__is_a_file?(certificate_path)
  certificate_passphrase_code_path = "#{certificate_path}.pass"
  abort "certificate_pass file exists already: #{certificate_passphrase_code_path}" if e__is_a_file?(certificate_passphrase_code_path)
  abort "ERROR: the mandatory format for passphrase_code is [nnnn] (4 numbers enclosed in brackets) : #{passphrase_code}" unless certificate_passphrase_code_path =~ /^\[[0-9]{4}\]$/
  case default_cert_file_option
  when '-c'
    default_cert_file="#{path}/ec1_user.openssh.default_certificate"
  when '-b'
    echo "INFO: bypassing default_cert_file creation"
  else
    abort "ERROR: default_cert_file_option must be either -c (create) or -b (bypass) (currently set as: #{default_cert_file_option})"
  end
  #puts "certificate_passphrase_code_path = #{certificate_passphrase_code_path}"
  command = "ssh-keygen -f #{certificate_path} -C #{name}"
  command << " -P #{passphrase}" unless passphrase.nil?
  system("#{command}")
  abort "Error creating certificate file #{certificate_path}" unless e__is_a_file?(certificate_path)
  e__file_save_nl(passphrase_code, certificate_passphrase_code_path)
  abort "Error creating certificate_passcode file: #{certificate_passphrase_code_path}" unless e__is_a_file?(certificate_passphrase_code_path)
  e__file_save(name, default_cert_file)
  abort "Error creating default_cert_file file: #{default_cert_file}" unless e__is_a_file?(default_cert_file)
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
