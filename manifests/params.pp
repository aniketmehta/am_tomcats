class am_tomcats::params {

  $default_tomcat_release = "7.0.54"
  # fixed wrapper_release because of static tomcat-wrapper.sh in templates (future: augeas fix?)
  $default_wrapper_release = "3.5.21"
  $default_java_home = "/usr/lib/jvm/java-7-oracle"
  $default_download_tomcat_from= "http://archive.apache.org"
  $default_download_wrapper_from = "http://wrapper.tanukisoftware.com/download"
#  $default_tomcat_user = "tomcat"
#  $default_tomcat_locales = "de_DE@euro"

}
