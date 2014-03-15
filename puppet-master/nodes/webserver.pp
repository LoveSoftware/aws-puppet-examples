node 'webserver' {

    package { "php5"
	ensure => installed
    }

    package { "nginx":
	ensure => installed

}