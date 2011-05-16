define redis::install($ensure=present, $bin_dir="") {
  $version = $name
  $redis_src = "/usr/local/src/redis-${version}"

  if $ensure == 'present' {
    @package { "build-essential":
      ensure => $ensure,
    }
    realize(Package["build-essential"])

    file { $redis_src:
      ensure => "directory",
    }

    exec { "fetch redis ${version}": 
      command => "curl -sL https://github.com/antirez/redis/tarball/${version} | tar --strip-components 1 -xz",
      cwd => $redis_src,
      creates => "${redis_src}/Makefile",
      require => File[$redis_src],
    }

    exec { "install redis ${version}":
      command => "make && /etc/init.d/redis-server stop && make install PREFIX=/usr/local",
      cwd => "${redis_src}/src",
      unless => "test `redis-server --version | cut -d ' ' -f 4` = '${version}'",
      require => [Exec["fetch redis ${version}"], Package["build-essential"]]
    }

  } elsif $ensure == 'absent' {

    file { $redis_src:
      ensure => $ensure,
      recurse => true,
      purge => true,
      force => true,
    }

    file { ["$bin_dir/redis-benchmark",
            "$bin_dir/redis-check-aof",
            "$bin_dir/redis-check-dump",
            "$bin_dir/redis-cli",
            "$bin_dir/redis-server"]:
      ensure => $ensure,
    }
  }
}
