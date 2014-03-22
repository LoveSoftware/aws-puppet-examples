node 'webserver' {

	class { "nginx": }

	nginx::resource::vhost { 'test.webserver.dev':
 	  www_root => '/vagrant/www',
	}
}