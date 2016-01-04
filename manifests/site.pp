exec{'/usr/bin/apt-get update':}

exec{'/usr/bin/apt-get upgrade -y':
  require => Exec['/usr/bin/apt-get update'],
}

Exec['/usr/bin/apt-get upgrade -y'] -> Package <| |>

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
exec /usr/local/bin/bundle exec dotenv "${@}"
',
}

file{'/etc/apt/sources.list.d/pgdg.list':
  ensure  => file,
  content => 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main
',
}

exec{'/usr/bin/wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | /usr/bin/apt-key add -':}

File['/etc/apt/sources.list.d/pgdg.list'] -> Exec['/usr/bin/wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | /usr/bin/apt-key add -'] -> Exec['/usr/bin/apt-get update']

$ruby_series  = '2.2'
$ruby_version = "${ruby_series}.4"
exec{'download-ruby':
  command => "/usr/bin/wget --quiet -O /usr/local/src/ruby-${ruby_version}.tar.gz http://cache.ruby-lang.org/pub/ruby/${ruby_series}/ruby-${ruby_version}.tar.gz",
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
