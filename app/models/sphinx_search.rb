require 'sphinx'

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

    # set the host and port here
    client = Sphinx::Client.new

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

end
