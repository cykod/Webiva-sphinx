class SphinxSearch

  def self.webiva_search_handler_info
    { 
      :name => 'Sphinx Search Engine',
      :controller => '/sphinx/admin',
      :action => 'options',
      :class => 'SphinxSearch'
    }
  end

  def self.search(language, search, options)
    client = Sphinx::Client.new

    client.SetServer self.sphinx_host, self.sphinx_port

    client.SetMatchMode Sphinx::AdminController.default_match_mode

    client.SetFilter 'language', language

    if options[:conditions]
      client.SetFilter('content_type_id', options[:conditions][:content_type_id]) if options[:conditions][:content_type_id]
      client.SetFilter('protected_result', 0) if options[:conditions][:protected_result] && options[:conditions][:protected_result].blank?
      client.SetFilter('search_result', 1) if options[:conditions][:search_result] && ! options[:conditions][:search_result].blank?
    end

    client.SetLimits(options[:offset], options[:limit]) if options[:offset] && options[:limit]

    values = []
    result = client.Query search, 'dist'
    if result['matches'].length > 0
      ids = result['matches'].map { |match| match['id'] }

      nodes = ContentNodeValue.search_items(ids).index_by(&:id)

      values = ids.map { |id| nodes[id] }

      docs = values.map(&:body)
      excerpts = client.BuildExcerpts(docs, 'main', search)
      values.each_index { |index| values[index].excerpt = excerpts[index] }
    end

    [values, result['total_found']]
  end

  def self.run_worker_setup_sphinx_conf(db_name)
    params = { 'db_name' => db_name,
               'searchd' => "#{self.sphinx_host}:#{self.sphinx_port}"
             }

    DomainModel.run_worker 'SphinxSearch', nil, 'setup_sphinx_conf', params
  end

  def self.setup_sphinx_conf(params = {})
    db_name = params['db_name']
    searchd = params['searchd'] ? params['searchd'] : '';
    ok = `#{RAILS_ROOT}/script/generate sphinx -f #{db_name} #{searchd}`
  end

  def self.sphinx_host
    return DataCache.local_cache('sphinx_host') if DataCache.local_cache('sphinx_host')

    sphinx_host = Configuration.get('sphinx_host', nil)
    if sphinx_host.nil?
      domain = Domain.find(DomainModel.active_domain_id)
      config = YAML::load( File.open("#{RAILS_ROOT}/config/sites/#{domain.database}.yml") )
      sphinx_host = config['production']['host']
    end

    DataCache.put_local_cache('sphinx_host', sphinx_host)
  end

  def self.sphinx_port
    return DataCache.local_cache('sphinx_port') if DataCache.local_cache('sphinx_port')

    sphinx_port = Configuration.get('sphinx_base_port', 3311).to_i + DomainModel.active_domain_id.to_i

    DataCache.put_local_cache('sphinx_port', sphinx_port)
  end

  def self.default_match_mode
    self.module_options.match_mode
  end
end
