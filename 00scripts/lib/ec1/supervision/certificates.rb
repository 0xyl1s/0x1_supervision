# encoding: utf-8
# tested with ruby 1.9.3

module Ec1 module Supervision module Security

class Certificates
require 'ec1/lib/toolkit/standard.rb'
include Ec1::Lib::Toolkit::Standard

def create(path, name, passphrase_code, default_cert_file_option, passphrase=nil)
  abort "path unavailable: #{path}" unless e__is_a_dir?(path)
  certificate_path = File.join(path, name)
  abort "certificate file exists already: #{certificate_path}" if e__is_a_file?(certificate_path)
  certificate_passphrase_code_path = "#{certificate_path}.passcode"
  abort "certificate_pass file exists already: #{certificate_passphrase_code_path}" if e__is_a_file?(certificate_passphrase_code_path)
  abort "ERROR: the mandatory format for passphrase_code is [nnnn] (4 numbers enclosed in brackets) : #{passphrase_code}" unless "#{passphrase_code}" =~ /^\[[0-9]{4}\]$/
  case default_cert_file_option
  when '-c'
    openssh_defcert_file="#{path}/user.openssh_defcert"
    # TODO: use ruby symlink creation command instead of system util
    system("(cd #{path} ; ln -s #{name} id_rsa ; ln -s #{name}.pub id_rsa.pub)")
  when '-b'
    puts "INFO: bypassing openssh_defcert_file creation"
  else
    abort "ERROR: default_cert_file_option must be either -c (create) or -b (bypass) (currently set as: #{default_cert_file_option})"
  end
  command = "ssh-keygen -f #{certificate_path} -C #{name}"
  command << " -P #{passphrase}" unless passphrase.nil?
  system("#{command}")
  abort "Error creating certificate file #{certificate_path}" unless e__is_a_file?(certificate_path)
  e__file_save_nl(passphrase_code, certificate_passphrase_code_path)
  abort "Error creating certificate_passcode file: #{certificate_passphrase_code_path}" unless e__is_a_file?(certificate_passphrase_code_path)
  if openssh_defcert_file
    e__file_save_nl(name, openssh_defcert_file)
    abort "Error creating openssh_defcert_file file: #{openssh_defcert_file}" unless e__is_a_file?(openssh_defcert_file)
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
