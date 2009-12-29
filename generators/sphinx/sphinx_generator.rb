class SphinxGenerator < Rails::Generator::Base
  attr_accessor :db_host, :db_port, :db_user, :db_pass, :db_name, :base_path, :searchd_host, :searchd_port

  def manifest

    @db_name = args.shift
    raise 'db name not specified' unless @db_name

    config = YAML::load( File.open(destination_path("config/sites/#{db_name}.yml")) )
    raise "config file not found (config/sites/#{db_name}.yml)" unless config

    @db_host = config['production']['host']
    @db_port = config['production']['port'] ? config['production']['port'] : 3306
    @db_user = config['production']['username']
    @db_pass = config['production']['password']

    path = "tmp/data/search/sphinx/#{@db_name}"
    @base_path = destination_path path

    @searchd_host = @db_host
    @searchd_port = 3312

    searchd =  args.shift
    if searchd
      @searchd_host, @searchd_port = searchd.split ':'
      raise "invalid searchd host:port (#{searchd})" unless @searchd_host && @searchd_port
    end

    record do |m|
      m.directory "#{path}/index"
      m.directory "#{path}/logs"
      m.directory "#{path}/run"
      m.template 'config/sites/sphinx.conf', "config/sites/sphinx_#{db_name}.conf"
    end
  end

  def banner
    "Usage: #{$0} #{spec.name} <db name> [<searchd host>:<searchd port>]"
  end
end
