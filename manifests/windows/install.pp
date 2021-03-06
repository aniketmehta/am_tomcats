# tomcats::windows::install resource will be used by multiple/tomcatxx.pp classes

define am_tomcats::windows::install ( 
  $tomcat_number,
  $tomcat_release,
  $parent_inst_dir,
  $wrapper_release,
  $java_home,
  $download_tomcat_from,
  $download_wrapper_from,
  $path_to_7zip,
  $autostart,
) {

  ################################################
  #                                              #
  #   Definition of variables for installation   #
  #                                              #
  ################################################

  # set path for exec in whole class
  # Example: Exec  { path => [ "C:\\Windows\\sysnative\\WindowsPowerShell\\v1.0\\","C:\\Windows\\sysnative\\","C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\","C:\\Windows\\System32\\wbem\\" ] }
  Exec  { path => [ "C:\\Windows\\System32","${path_to_7zip}" ] }

  # Extract major version from tomcat_release
  $majorversion = regsubst($tomcat_release,'^(\d+)\.(\d+)\.(\d+)$','\1')

  case $majorversion {
    5: { $lib_path = "common\\lib" }
    default: { $lib_path = "lib"}
  }

  # Extract minor version from tomcat_release
  $minorversion = regsubst($tomcat_release,'^(\d+)\.(\d+)\.(\d+)$','\2')

  # Define tomcat package version (i.e. apache-tomcat-7.0)
  $pkg_tomcat = "apache-tomcat-${majorversion}.${minorversion}"

  # Define tomcat ports
  case $tomcat_number {
    01, 1: { $http_port = '8080'
      $shutdown_port = '8005'
      $ajp_port = '8009'
      $jmx_port = '9017'
    }
    02, 2: { $http_port = '8090'
      $shutdown_port = '8006'
      $ajp_port = '8010'
      $jmx_port = '9018'
    }
    03, 3: { $http_port = '8091'
      $shutdown_port = '8007'
      $ajp_port = '8011'
      $jmx_port = '9019'
    }
    04, 4: { $http_port = '8092'
      $shutdown_port = '8008'
      $ajp_port = '8012'
      $jmx_port = '9020'
    }
    05, 5: { $http_port = '8093'
      $shutdown_port = '8013'
      $ajp_port = '8014'
      $jmx_port = '9021'
    }
    06, 6: { $http_port = '8094'
      $shutdown_port = '8015'
      $ajp_port = '8016'
      $jmx_port = '9022'
    }
    07, 7: { $http_port = '8095'
      $shutdown_port = '8017'
      $ajp_port = '8018'
      $jmx_port = '9023'
    }
    08, 8: { $http_port = '8096'
      $shutdown_port = '8019'
      $ajp_port = '8020'
      $jmx_port = '9024'
    }
    09, 9: { $http_port = '8097'
      $shutdown_port = '8021'
      $ajp_port = '8022'
      $jmx_port = '9025'
    }
    # Dynamic port number generation from tomcat 10 and higher
    default: {  $http_port = "9${tomcat_number}0"
        $shutdown_port = "9${tomcat_number}1"
        $ajp_port = "9${tomcat_number}2"
        $jmx_port = "9${tomcat_number}3"
    }
  }

  # Define tomcat[xx] installation directory
  $inst_dir = "${parent_inst_dir}\\Tomcat${tomcat_number}"

  # Define tomcat package file name
  case $majorversion {
    5: { $pkg_tomcat_filename = "apache-tomcat-${tomcat_release}" }
    default: { $pkg_tomcat_filename = "apache-tomcat-${tomcat_release}-windows-${architecture}" }
  }

  # Define wrapper package
  case $architecture {
    x86: {
      $pkg_wrapper = "wrapper-windows-x86-32-${wrapper_release}"
    }
    x64: {
      $pkg_wrapper = "wrapper-windows-x86-64-${wrapper_release}-st"
    }
  }


  ###############################
  #                             #
  #     Installation Tomcat     #
  #                             #
  ###############################

  # create parent inst dir and source dir at one time
  exec { "source_dir_tomcats_${tomcat_number}":
    command => "cmd.exe /c mkdir ${parent_inst_dir}\\Sources",
    creates => "${parent_inst_dir}\\Sources",
  }

  # tomcat[xx] installation directory
  file { "${inst_dir}":
    ensure  => directory,
    require => Exec [ "source_dir_tomcats_${tomcat_number}" ],
  }

  # extract zipped tomcat archive from file share into sources directory
  exec { "extract_tomcat_source_${tomcat_number}":
    command => "7z x ${download_tomcat_from}\\apache-tomcat\\releases\\${tomcat_release}\\${pkg_tomcat_filename}.zip -y -o${parent_inst_dir}\\Sources",
    creates => "${parent_inst_dir}\\Sources\\apache-tomcat-${tomcat_release}\\bin",
    require => File [ "${inst_dir}" ],
  }

  exec { "clean_tomcat_source_conf_${tomcat_number}":
    cwd => "${parent_inst_dir}\\Sources\\apache-tomcat-${tomcat_release}\\conf",
    command => "cmd.exe /c if exist context.xml del catalina.properties context.xml server.xml tomcat-users.xml web.xml",
    refreshonly => true, 
    subscribe => Exec [ "extract_tomcat_source_${tomcat_number}" ],
  }

  case $majorversion {
    5: {
      exec { "clean_tomcat_source_webapps_${tomcat_number}":
        cwd => "${parent_inst_dir}\\Sources\\apache-tomcat-${tomcat_release}\\webapps",
        command => "cmd.exe /c if exist ROOT rmdir /s /q ROOT balancer jsp-examples servlets-examples tomcat-docs webdav",
        refreshonly => true,
        subscribe => Exec [ "clean_tomcat_source_conf_${tomcat_number}" ],
      }
    }
    # for tomcat 7
    default: {
      exec { "clean_tomcat_source_webapps_${tomcat_number}":
        cwd => "${parent_inst_dir}\\Sources\\apache-tomcat-${tomcat_release}\\webapps",
        command => "cmd.exe /c if exist ROOT rmdir /s /q ROOT docs examples",
        refreshonly => true,
        subscribe => Exec [ "clean_tomcat_source_conf_${tomcat_number}" ],
      }
    }
  }


  # xcopy extracted directory (i.e. apache-tomcat-7.0.52) to ${inst_dir}\\${pkg_tomcat}-directory (i.e. apache-tomcat-7.0)
  # xcopy doc - http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/xcopy.mspx?mfr=true
  exec { "xcopy_tomcat_${inst_dir}":
    command => "cmd.exe /c xcopy ${parent_inst_dir}\\Sources\\apache-tomcat-${tomcat_release}\\*.* ${inst_dir}\\${pkg_tomcat}\\ /e /s /h",
    creates => "${inst_dir}\\${pkg_tomcat}\\bin",
    require => Exec [ "clean_tomcat_source_webapps_${tomcat_number}" ],
  }

  # copy tomcat5.exe and tcnative-1.dll into bin dir, if tomcat5 and x64 architecture
  if ($majorversion == '5') and ($::architecture == 'x64') { 
    exec { "copy_tcnative_${inst_dir}":
      command => "cmd.exe /c copy ${parent_inst_dir}\\Sources\\apache-tomcat-${tomcat_release}\\bin\\x64\\tcnative-1.dll ${inst_dir}\\${pkg_tomcat}\\bin\\",
      refreshonly => true,
      subscribe => Exec [ "xcopy_tomcat_${inst_dir}" ],
    }
    exec { "copy_tomcat5exe_${inst_dir}":
      command => "cmd.exe /c copy ${parent_inst_dir}\\Sources\\apache-tomcat-${tomcat_release}\\bin\\x64\\tomcat5.exe ${inst_dir}\\${pkg_tomcat}\\bin\\",
      refreshonly => true,
      subscribe => Exec [ "xcopy_tomcat_${inst_dir}" ],
    }
  }

  file { "${inst_dir}\\${pkg_tomcat}\\conf\\tomcat-users.xml":
    content => template("tomcats/windows/tomcat-users.xml.erb"),
    replace => false,
    source_permissions => ignore,
    require => Exec ["xcopy_tomcat_${inst_dir}"],
  }

  file { "${inst_dir}\\${pkg_tomcat}\\conf\\catalina.properties":
    content => template("tomcats/windows/catalina.properties${majorversion}.erb"),
    replace => false,
    source_permissions => ignore,
    require => Exec ["xcopy_tomcat_${inst_dir}"],
  }

  file { "${inst_dir}\\${pkg_tomcat}\\conf\\context.xml":
    content => template("tomcats/windows/context${majorversion}.xml.erb"),
    replace => false,
    source_permissions => ignore,
    require => Exec ["xcopy_tomcat_${inst_dir}"],
  }

  file { "${inst_dir}\\${pkg_tomcat}\\conf\\server.xml":
    content => template("tomcats/windows/server${majorversion}.xml.erb"),
    replace => false,
    source_permissions => ignore,
    require => Exec ["xcopy_tomcat_${inst_dir}"],
  }

  file { "${inst_dir}\\${pkg_tomcat}\\conf\\web.xml":
    content => template("tomcats/windows/web${majorversion}.xml.erb"),
    replace => false,
    source_permissions => ignore,
    require => Exec ["xcopy_tomcat_${inst_dir}"],
  }

  file { "${inst_dir}\\ports.txt":
    ensure => present,
    content => "# File managed by puppet \r\n
\r\n
HTTP-Port: ${http_port} \r\n
AJP-Port: ${ajp_port} \r\n
Shutdown-Port: ${shutdown_port} \r\n",
    source_permissions => ignore,
    require => Exec ["xcopy_tomcat_${inst_dir}"],
  }

  # deploy special tomcat start.bat, that ca be modified by users
  file { "${inst_dir}\\${pkg_tomcat}\\bin\\start.bat":
    content => template("tomcats/windows/start.bat.erb"),
    replace => false,
    source_permissions => ignore,
    require => Exec ["xcopy_tomcat_${inst_dir}"],
  }




  ################################
  #                              #
  #     Installation Wrapper     #
  #                              #
  ################################

  # download and extract wrapper archive
  # extract zipped archive from file share into ${inst_dir}
  exec { "extract_wrapper_${inst_dir}":
    command => "7z x ${download_wrapper_from}\\java-wrapper\\releases\\${wrapper_release}\\${pkg_wrapper}.zip -y -o${parent_inst_dir}\\Sources",
    creates => "${parent_inst_dir}\\Sources\\${pkg_wrapper}\\bin",
    require => Exec [ "xcopy_tomcat_${inst_dir}" ],
  }

  # copy wrapper files into tomcat installation directory
  # wrapper doc - http://wrapper.tanukisoftware.com/doc/english/integrate-start-stop-win.html
  exec { "${inst_dir}\\${pkg_tomcat}\\bin\\wrapper.exe":
    command => "cmd.exe /c copy ${parent_inst_dir}\\Sources\\${pkg_wrapper}\\bin\\wrapper.exe ${inst_dir}\\${pkg_tomcat}\\bin\\wrapper.exe",
    creates => "${inst_dir}\\${pkg_tomcat}\\bin\\wrapper.exe",
    require => Exec [ "extract_wrapper_${inst_dir}" ],
  }
  exec { "${inst_dir}\\${pkg_tomcat}\\bin\\Tomcat.bat":
    command => "cmd.exe /c copy ${parent_inst_dir}\\Sources\\${pkg_wrapper}\\src\\bin\\App.bat.in ${inst_dir}\\${pkg_tomcat}\\bin\\Tomcat.bat",
    creates => "${inst_dir}\\${pkg_tomcat}\\bin\\Tomcat.bat",
    require => Exec [ "extract_wrapper_${inst_dir}" ],
  }
  exec { "${inst_dir}\\${pkg_tomcat}\\bin\\InstallTomcat-NT.bat":
    command => "cmd.exe /c copy ${parent_inst_dir}\\Sources\\${pkg_wrapper}\\src\\bin\\InstallApp-NT.bat.in ${inst_dir}\\${pkg_tomcat}\\bin\\InstallTomcat-NT.bat",
    creates => "${inst_dir}\\${pkg_tomcat}\\bin\\InstallTomcat-NT.bat",
    require => Exec [ "extract_wrapper_${inst_dir}" ],
  }
  exec { "${inst_dir}\\${pkg_tomcat}\\bin\\UninstallTomcat-NT.bat":
    command => "cmd.exe /c copy ${parent_inst_dir}\\Sources\\${pkg_wrapper}\\src\\bin\\UninstallApp-NT.bat.in ${inst_dir}\\${pkg_tomcat}\\bin\\UninstallTomcat-NT.bat",
    creates => "${inst_dir}\\${pkg_tomcat}\\bin\\UninstallTomcat-NT.bat",
    require => Exec [ "extract_wrapper_${inst_dir}" ],
  }
  exec { "${inst_dir}\\${pkg_tomcat}\\${lib_path}\\wrapper.dll":
    command => "cmd.exe /c copy ${parent_inst_dir}\\Sources\\${pkg_wrapper}\\lib\\wrapper.dll ${inst_dir}\\${pkg_tomcat}\\${lib_path}\\wrapper.dll",
    creates => "${inst_dir}\\${pkg_tomcat}\\${lib_path}\\wrapper.dll",
    require => Exec [ "extract_wrapper_${inst_dir}" ],
  }
  exec { "${inst_dir}\\${pkg_tomcat}\\${lib_path}\\wrapper.jar":
    command => "cmd.exe /c copy ${parent_inst_dir}\\Sources\\${pkg_wrapper}\\lib\\wrapper.jar ${inst_dir}\\${pkg_tomcat}\\${lib_path}\\wrapper.jar",
    creates => "${inst_dir}\\${pkg_tomcat}\\${lib_path}\\wrapper.jar",
    require => Exec [ "extract_wrapper_${inst_dir}" ],
  }
  exec { "${inst_dir}\\${pkg_tomcat}\\conf\\wrapper-license.conf":
    command => "cmd.exe /c copy ${parent_inst_dir}\\Sources\\${pkg_wrapper}\\conf\\wrapper-license.conf ${inst_dir}\\${pkg_tomcat}\\conf\\wrapper-license.conf",
    creates => "${inst_dir}\\${pkg_tomcat}\\conf\\wrapper-license.conf",
    require => Exec [ "extract_wrapper_${inst_dir}" ],
  }

  # deploy wrapper configuration (after copy wrapper files into tomcat installation directory)
  file { "${inst_dir}\\${pkg_tomcat}\\conf\\wrapper.conf":
    content => template('tomcats/windows/wrapper.conf.erb'),
    source_permissions => ignore,
    require => Exec [ "${inst_dir}\\${pkg_tomcat}\\${lib_path}\\wrapper.jar" ],
  }
  file { "${inst_dir}\\${pkg_tomcat}\\conf\\wrapper-custom.conf":
    content => template('tomcats/windows/wrapper-custom.conf.erb'),
    replace => false,
    source_permissions => ignore,
    require => Exec [ "${inst_dir}\\${pkg_tomcat}\\${lib_path}\\wrapper.jar" ],
  }

  # register wrapper as windows service and create logfile
  exec { "service_wrapper_${inst_dir}":
    path => "${inst_dir}\\${pkg_tomcat}\\bin",
    command => "${inst_dir}\\${pkg_tomcat}\\bin\\InstallTomcat-NT.bat",
    creates => "${inst_dir}\\${pkg_tomcat}\\bin\\InstallTomcat-NT.log",
    require => File [ "${inst_dir}\\${pkg_tomcat}\\conf\\wrapper.conf" ],
  }
  file { "${inst_dir}\\${pkg_tomcat}\\bin\\InstallTomcat-NT.log":
    ensure => present,
    content => "# File managed by puppet
Wrapper registered as Windows service \"Tomcat${tomcat_number}\"",
    source_permissions => ignore,
    require => Exec [ "service_wrapper_${inst_dir}" ],
  }

}
