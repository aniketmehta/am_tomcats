class am_tomcats::instance (
  $tomcat_instances = {
    # these values you will see as default in your ENC like The Foreman
    tomcat01 => {
      tomcat_number => '01',
      tomcat_release => '7.0.54',
      java_home => '/usr/lib/jvm/java-7-oracle',
    },
  },
  $tomcat_instances_defaults = {
      # these values are taken if you won't specify values in your ENC like The Foreman
      tomcat_number => '01',
      tomcat_release => '7.0.54',
      wrapper_release => '3.5.21',
      java_home => '/usr/lib/jvm/java-7-oracle',
      download_tomcat_from => 'http://archive.apache.org',
      download_wrapper_from => 'http://wrapper.tanukisoftware.com/download',      
  },
) {

  # load tomcat default stuff like system user, group, etc
  require am_tomcats

  # load tomcat default configuration parameters, which are used when no parameters are set (undef)
  require am_tomcats::params

  # call tomcats::install define to configure each tomcat instance
  create_resources(am_tomcats::install, $tomcat_instances, $tomcat_instances_defaults)

}
