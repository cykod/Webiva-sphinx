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

    searchd = Sphinx::AdminController.searchd
    searchd_host, searchd_port = searchd.split ':'
    client.SetServer searchd_host, searchd_port.to_i

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

      docs = values.map { |value| value.body }
      excerpts = client.BuildExcerpts(docs, 'main', search)
      values.each_index { |index| values[index].excerpt = excerpts[index] }
    end

    [values, result['total_found']]
  end

  def self.run_worker_setup_sphinx_conf(db_name, searchd=nil)
    params = { 'db_name' => db_name }
    params['searchd'] = searchd if ! searchd.blank?

    DomainModel.run_worker 'SphinxSearch', nil, 'setup_sphinx_conf', params
  end

  def self.setup_sphinx_conf(params = {})
    db_name = params['db_name']
    searchd = params['searchd'] ? params['searchd'] : '';
    ok = `#{RAILS_ROOT}/script/generate sphinx #{db_name} #{searchd}`
  end
end
