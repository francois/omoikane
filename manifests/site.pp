exec{'/usr/bin/apt-get update':}

exec{'/usr/bin/apt-get upgrade -y':
  require => Exec['/usr/bin/apt-get update'],
}

Exec['/usr/bin/apt-get upgrade -y'] -> Package <| |>

package{[
  'nodejs',
  'daemontools',
  'rabbitmq-server',
  'erlang',
]:
  ensure => absent,
}

package{[
  'vim-nox',
  'byobu',
  'ruby-full',
  'zsh',
  'ruby',
  'ruby-dev',
  'postgresql-9.3',
  'postgresql-contrib-9.3',
  'postgresql-client-9.3',
  'libpq-dev',
  'libpq5',
  'git',
  'build-essential',
  'htop',
  'ntp',
]:
  ensure => latest,
}

exec{'/usr/local/bin/ruby -S gem install --no-rdoc --no-ri bundler':
  unless => '/usr/local/bin/ruby -S gem list --local | /bin/grep --quiet bundler',
  require => Exec['install-ruby'],
}

file{'/usr/local/bin/edb':
  ensure  => file,
  mode    => 0775,
  content => '#!/bin/sh
exec /usr/bin/envdir .env /usr/local/bin/bundle exec "${@}"',
}

file{'/etc/apt/sources.list.d/pgdg.list':
  ensure  => file,
  content => 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main
',
}

file{'/etc/apt/sources.list.d/rabbitmq.list':
  ensure  => file,
  content => 'deb http://www.rabbitmq.com/debian/ testing main
',
}


file{'/etc/apt/sources.list.d/erlang-solutions.list':
  ensure  => file,
  content => 'deb http://packages.erlang-solutions.com/debian wheezy contrib
',
}

exec{'/usr/bin/wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | /usr/bin/apt-key add -':}
exec{'/usr/bin/wget --quiet -O - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | /usr/bin/apt-key add -':}
exec{'/usr/bin/wget --quiet -O - http://packages.erlang-solutions.com/debian/erlang_solutions.asc | /usr/bin/apt-key add -':}

File['/etc/apt/sources.list.d/pgdg.list'] -> Exec['/usr/bin/wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | /usr/bin/apt-key add -'] -> Exec['/usr/bin/apt-get update']
File['/etc/apt/sources.list.d/rabbitmq.list'] -> Exec['/usr/bin/wget --quiet -O - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | /usr/bin/apt-key add -'] -> Exec['/usr/bin/apt-get update']
File['/etc/apt/sources.list.d/erlang-solutions.list'] -> Exec['/usr/bin/wget --quiet -O - http://packages.erlang-solutions.com/debian/erlang_solutions.asc | /usr/bin/apt-key add -'] -> Exec['/usr/bin/apt-get update']

$ruby_version = '2.1.3'
exec{'download-ruby':
  command => "/usr/bin/wget --quiet -O /usr/local/src/ruby-${ruby_version}.tar.gz http://cache.ruby-lang.org/pub/ruby/2.1/ruby-${ruby_version}.tar.gz",
  creates => "/usr/local/src/ruby-${ruby_version}.tar.gz",
}

exec{'extract-ruby':
  command => "/bin/tar --extract --gunzip --file ruby-${ruby_version}.tar.gz",
  cwd     => '/usr/local/src',
  creates => "/usr/local/src/ruby-${ruby_version}",
  require => Exec['download-ruby'],
}

exec{'install-ruby':
  command => "/usr/local/src/ruby-${ruby_version}/configure --prefix=/usr/local && /usr/bin/make --jobs 2 && /usr/bin/make install",
  cwd     => "/usr/local/src/ruby-${ruby_version}",
  creates => '/usr/local/bin/ruby',
  require => Package['build-essential'],
  timeout => 0, # disregard timeout
}
