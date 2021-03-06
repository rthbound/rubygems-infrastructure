#
# Cookbook Name:: rubygems-app
# Recipe:: delayed_job
#

redis_host = data_bag_item('hosts', 'redis')['environments'][node.chef_environment]
redis_ip = search('node', "name:#{redis_host}.#{node.chef_environment}.rubygems.org")[0]['ipaddress']

runit_service 'delayed_job' do
  owner 'deploy'
  group 'deploy'
  default_logger true
  env(
    'RAILS_ENV' => node.chef_environment,
    'REDISTOGO_URL' => "redis://#{redis_ip}:6379/0"
  )
  options(
    owner: 'deploy',
    group: 'deploy',
    bundle_command: '/usr/local/bin/bundle',
    rails_env: node.chef_environment
  )
  action ::File.exist?('/applications/rubygems/current') ? :enable : :disable
end

sudo 'deploy-delayed_job' do
  user 'deploy'
  commands [
    '/etc/init.d/delayed_job *',
    '/usr/sbin/service delayed_job *',
    '/usr/bin/sv -w * delayed_job'
  ]
  nopasswd true
end

template '/usr/local/bin/background_job_stats.sh' do
  source 'background_job_stats.sh.erb'
  mode '0755'
  owner 'root'
  group 'root'
  variables(host: node.chef_environment == 'production' ? 'rubygems.org' : 'staging.rubygems.org')
end

cron 'background job stats collection' do
  user 'root'
  minute '*/1'
  command '/usr/local/bin/background_job_stats.sh'
end
