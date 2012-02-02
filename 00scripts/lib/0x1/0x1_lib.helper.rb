# encoding: utf-8
# tested with ruby 1.9.3

X_LIB_PATH = File.join(File.expand_path('~'), '.0x1/00mu/00sourcing/0x1_lib')

def x__load_modules(x__modules2load)
  abort "XERROR: x__modules2load must be an arry (#{x__modules2load.class})" unless x__modules2load.is_a?(Array)
  x__modules2load.each do |module2load|
    case module2load
    when :standard
      require_relative "#{X_LIB_PATH}/0x1/lib/toolkit/standard.rb"
      extend X::Lib::Toolkit::Standard
    when :online
      require_relative "#{X_LIB_PATH}/0x1/lib/toolkit/online.rb"
      extend X::Lib::Toolkit::Online
    else
      abort "XERROR: module2load: no such module as #{module2load}"
    end
  end
end

# ____________________________________________________________________
# >>>>>  projet epiculture/ec1   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#{{{
# Sources, Infos & Contact : http://www.epiculture.org
# Author: Pierre-Maël Crétinon
# License: GNU GPLv3 ( www.epiculture.org/ec1/LICENSE )
# Copyright: 2010-2012 Pierre-Maël Crétinon
# Sponsor: studio Helianova - http://studio.helianova.com
# ――――――――――――――――――――――――――――――――――――――#}}}
# vim: ft=ruby
