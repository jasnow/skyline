module Skyline::RefObjectHelper
  # Get the title of a ref_object.
  def ref_object_title(referable,default = "")
    return referable.default_variant_data.andand.navigation_title.to_s if referable.class.to_s == "Skyline::Page"
    return referable.name.to_s if referable.class.to_s == "Skyline::MediaFile"
    return referable.title.to_s if referable.respond_to?(:title)
    default
  end
  
  def ref_object_css_class(referable)
    case referable.andand.class.to_s
    when "Skyline::Page"
      "page"
    when "Skyline::MediaFile"
      "mediaFile #{referable.file_type}"
    else
      "external"
    end    
  end  
  

  # options[:object]      defaults to: form_builder.object.send(field) || form_builder.object.send("build_#{field}")
  # options[:container]   defaults to: form_builder.dom_id(field)
  def image_browser(form_builder, field, options = {})
    referable_field_browser(form_builder, field, :image, options)
  end
  
  def link_browser(form_builder, field, options = {})
    referable_field_browser(form_builder, field, :link, options)
  end
  
  def content_browser(form_builder, field, options = {})
    content_selection = options.delete(:article_classes)
    content_selection = content_selection.join(',') if content_selection.kind_of? Array
    
    referable_field_browser(form_builder, field, :content, options.merge(:content_selection => content_selection))
  end
  
  def referable_field_browser(form_builder, field, browser, options = {})
    options.reverse_merge! :object => form_builder.object.send(field) || form_builder.object.send("build_#{field}"), 
                           :container => nil,
                           :skip_class => false
                           
    if !options[:container]
      options[:container] = form_builder.dom_id(field)
      css_class = ref_object_css_class(options[:object].referable)
    else
      css_class = ""
    end

    c = []
      
    if options[:object].andand.marked_for_destruction?
      options[:object].referable_type = nil
      options[:object].referable_id = nil
    end
    
    form_builder.fields_for "#{field}_attributes", options[:object] do |linked_form|
      c << linked_form.hidden_field(:id) unless linked_form.object.new_record?    
      c << linked_form.hidden_field(:referable_type, :class => "referable_type")
      c << linked_form.hidden_field(:referable_id, :class => "referable_id")
      c << linked_form.hidden_field(:_destroy, :class => "referable_delete", :value => 0)    
      linked_form.fields_for "referable_attributes", linked_form.object.referable do |referable_form|
        c << hidden_field_tag(referable_form.object_name + "[uri]", referable_form.object.respond_to?(:uri) ? referable_form.object.uri : "", :class => "link_custom_url")
      end

      
      deselect_button = link_to_function(button_text(:delete), "Application.Browser.unlink('#{options[:container]}');", :class => "button small red delete").html_safe
      if options[:content_selection].present?
        browse_button = link_to_function(button_text(:browse), "Application.Browser.browse#{browser.to_s.camelcase}For('#{options[:container]}', {dialogParams: {content_selection: '#{options[:content_selection]}'}});", :class => "button small").html_safe
      else
        browse_button = link_to_function(button_text(:browse), "Application.Browser.browse#{browser.to_s.camelcase}For('#{options[:container]}');", :class => "button small").html_safe
      end
    
      c << content_tag("div", {:class => "not-linked"}) do
        nl = []
        nl << content_tag("span",t(:nothing_selected, :scope => [:browser,browser]), {:class => "title"}, false)
        nl << browse_button
        nl.join.html_safe
      end
      
      c << content_tag("div", {:class => "linked"}) do
        l = []
        referable_title = content_tag("span", ref_object_title(linked_form.object.andand.referable) + " ", :id => linked_form.dom_id(:title), :class => "title referable_title")
        l << t(:links_to, :scope => [:browser,browser], :referable_title => referable_title)
        l << deselect_button
        l << "&nbsp;"
        l << browse_button
        l.join.html_safe
      end
      
      c = content_tag("div", c.join.html_safe, :class => "relatesTo #{"linked" if linked_form.object.present? && !linked_form.object.andand.marked_for_destruction?}")
    end

    content_tag("div", c, :id => form_builder.dom_id(field), :class => css_class) + form_builder.fieldset_errors(field)
  end
end
