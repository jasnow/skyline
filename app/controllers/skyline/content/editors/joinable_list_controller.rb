class Skyline::Content::Editors::JoinableListController < Skyline::Skyline2Controller

  helper "skyline/content"
  before_filter :get_classes
  
  def index
    @filter = filter_from_params_or_default
    @elements = @target_klass.paginate_for_cms(:page => params[:page], :per_page => 10, :self_referential => false, :filter => @filter).all
    @title_field = @target_klass.fields[@target_klass.settings.title_field]
  end
  
  def new
    if @assoc.through_reflection
      @target = @target_klass.find(params[:target_id])
      @object = @source_object.send(@assoc.through_reflection.name).build(@assoc.source_reflection.name => @target)
    else
      @object = @target_klass.find(params[:target_id])
    end
  end
  
  def cancel
  end

  protected
  
  def get_classes
    @source_klass = @implementation.content_class(params[:source_type])
    @source_object = @source_klass.find_by_id(params[:source_id]) || @source_klass.new    
    @assoc = @source_klass.reflect_on_association(params[:association].to_sym)
    @target_klass = @assoc.klass    
  end
  
  def default_url_options(options)
    options.update(:source_type => params[:source_type], :source_id => params[:source_id], :association => params[:association])
  end

  # GEt filter from params, or use default if defined
  def filter_from_params_or_default
    # First priority is params
    return params[:filter] if params.has_key?(:filter) || params.has_key?("filter")
    
    # Field
    field = @source_klass.fields[@assoc.name]
    return {} if !field || field.default_filter.blank?
    
    if field.default_filter.kind_of?(Proc)
      filter = field.default_filter.call(@source_object)
    else
      filter = field.default_filter
    end
    filter || {}
  end
    
  
end
