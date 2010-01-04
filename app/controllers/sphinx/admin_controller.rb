# Copyright (C) 2009 Pascal Rettig.

class Sphinx::AdminController < ModuleController

  permit 'sphinx_config'

  component_info 'Sphinx', :description => 'Add support for Sphinx search engine on your website',
                           :access => :private

  register_handler :webiva, :search, 'SphinxSearch'

  register_permissions :sphinx, [  [ :manage, 'Manage Sphinx Search','Manage Sphinx Search'   ]]

  cms_admin_paths "options",
                  'Content' => { :controller => '/content' },
                  'Options' =>   { :controller => '/options' },
                  'Modules' =>  { :controller => '/modules' },
                  'Sphinx Options' => { :action => 'options' }


  public
  def options
    cms_page_path ['Options','Modules'], 'Sphinx Options'
    
    @options = self.class.module_options(params[:options])

    @domain = Domain.find(DomainModel.active_domain_id)

    if request.post? && @options.valid?
      Configuration.set_config_model(@options)

      SphinxSearch.run_worker_setup_sphinx_conf @domain['database']

      flash[:notice] = "Updated Sphinx search options".t 
      redirect_to :controller => '/modules'
      return
    end    
  end

  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end

  def self.default_match_mode
    self.module_options.match_mode
  end

  class Options < HashModel
    # default match mode only takes into account phrase rank, this mode sums phrase rank and word frequencies(BM25) together
    attributes :match_mode => Sphinx::Client::SPH_MATCH_EXTENDED

    integer_options :match_mode
  end
end
