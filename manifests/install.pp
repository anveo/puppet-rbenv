define rbenv::install(
  $user  = $title,
  $group = $user,
  $home  = '',
  $root  = '',
  $rc    = ".profile"
) {

  # Workaround http://projects.puppetlabs.com/issues/9848
  $home_path = $home ? { '' => "/home/${user}", default => $home }
  $root_path = $root ? { '' => "${home_path}/.rbenv", default => $root }

  $rbenvrc = "${home_path}/.rbenvrc"
  $shrc  = "${home_path}/${rc}"

  if ! defined( Class['rbenv::dependencies'] ) {
    require rbenv::dependencies
  }

  exec { "rbenv::checkout ${user}":
    command => "git clone git://github.com/sstephenson/rbenv.git ${root_path}",
    user    => $user,
    group   => $group,
    creates => $root_path,
    path    => ['/usr/bin', '/usr/sbin'],
    timeout => 100,
    cwd     => $home_path,
    require => Package['git']
  }

  exec { "rbenv::update ${user}":
    command   => "git checkout master && git pull --rebase && git checkout v0.4.0",
    user      => $user,
    group     => $group,
    #path      => ['/usr/bin', '/usr/sbin'],
    path      => ["/bin", "/usr/bin", "/usr/sbin"],
    timeout   => 100,
    cwd       => $root_path,
    require   => Exec["rbenv::checkout ${user}"],
    logoutput => false
  }

  file { "rbenv::rbenvrc ${user}":
    path    => $rbenvrc,
    owner   => $user,
    group   => $group,
    content => template('rbenv/dot.rbenvrc.erb'),
    require => Exec["rbenv::checkout ${user}"],
  }

  exec { "rbenv::shrc ${user}":
    command => "echo 'source ${rbenvrc}' >> ${shrc}",
    user    => $user,
    group   => $group,
    unless  => "grep -q rbenvrc ${shrc}",
    path    => ['/bin', '/usr/bin', '/usr/sbin'],
    require => File["rbenv::rbenvrc ${user}"],
  }

  file { "rbenv::cache-dir ${user}":
    owner   => $user,
    group   => $group,
    ensure  => directory,
    path    => "${root_path}/cache",
    require => Exec["rbenv::checkout ${user}"]
  }
}
