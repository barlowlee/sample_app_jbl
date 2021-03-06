module ApplicationHelper
  # Return a title on a per-page basis.
  def title
    base_title =  "Ruby on Rails Tutorial Sample App"
    if @title.nil? # @title is defined in pages_controller.rb
      base_title   # Ruby functions return the last value
    else
      "#{base_title} | #{@title}"  # this is called "string interpolation -
                                   #  putting  string variable in the middle of a string.
                                   #  interpolating a nil variable produces the empty string, not nil
    end
  end
  
  def logo
    image_tag("logo.png", :alt => "Sample App", :class => "round")
  end
  # A helper creates methods that can be called by views through embedded Ruby
  #    in this case 'title' will be called by 'application.html.erb' which is the
  #    main layout file for this site.
  #    The instance varable @title comes from the Pages controller
end
