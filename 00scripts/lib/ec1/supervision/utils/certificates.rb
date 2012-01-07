# encoding: utf-8
# tested with ruby 1.9.3

module Ec1 module Supervision module Utils module Security

class Certificates
require 'ec1/lib/toolkit/standard.rb'
include Ec1::Lib::Toolkit::Standard

def create(path, name, passphrase_code, passphrase=nil)
  abort "path unavailable: #{path}" unless e__is_a_dir?(path)
  certificate_path = File.join(path, name)
  abort "certificate file exists already: #{certificate_path}" if e__is_a_file?(certificate_path)
  certificate_passphrase_code_path = "#{certificate_path}.pass"
  abort "certificate_pass file exists already: #{certificate_passphrase_code_path}" if e__is_a_file?(certificate_passphrase_code_path)
  #puts "certificate_passphrase_code_path = #{certificate_passphrase_code_path}"
  #puts "passphrase_code = #{passphrase_code}"
  command = "ssh-keygen -f #{certificate_path} -C #{name}"
  command << " -P #{passphrase}" unless passphrase.nil?
  system("#{command}")
  abort "Error creating certificate file #{certificate_path}" unless e__is_a_file?(certificate_path)
  e__file_save_nl(passphrase_code, certificate_passphrase_code_path)
  abort "Error creating certificate_passcode file: #{certificate_passphrase_code_path}" unless e__is_a_file?(certificate_passphrase_code_path)
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
