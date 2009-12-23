
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
  end

end
