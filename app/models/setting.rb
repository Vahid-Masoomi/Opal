class Setting < ActiveRecord::Base
  validates_uniqueness_of :name
  validates_presence_of :name, :value
  
  def validate
  end
  
  def self.global_settings
    setting = Hash.new
    setting[:item_name] = Setting.get_setting("item_name")
    setting[:item_name_plural] = Setting.get_setting("item_name_plural")
    setting[:title] = Setting.get_setting("site_title")
    setting[:description] = Setting.get_setting("site_description")
    setting[:meta_keywords] = Setting.get_setting("site_keywords")
    setting[:meta_description] = setting[:description]
    setting[:meta_title] = setting[:title] + " - " + setting[:meta_description]
    setting[:theme] = Setting.get_setting("theme")
    setting[:items_per_page] = Setting.get_setting("items_per_page")
    setting[:include_child_category_items] = Setting.get_setting_bool("include_child_category_items")
    setting[:theme_url] =  "/themes/#{setting[:theme]}" # url for theme directory 
    setting[:theme_dir] =  File.join(RAILS_ROOT, "public", "themes", setting[:theme]) # system path for theme directory 
    return setting
  end
  
  def to_param # make custom parameter generator for seo urls
    "#{id}-#{name.gsub(/[^a-z0-9]+/i, '-')}"
  end
  
  def self.get_setting(name) # get a setting from the database, usually text-based string
    setting = Setting.find(:first, :conditions => ["name = ?", name], :limit => 1 )
    return setting.value
  rescue # ActiveRecord not found
    return ""
  end
  
  def self.get_setting_bool(name) # get a setting from the database return true or false depending on "1" or "0"
    setting = Setting.find(:first, :conditions => ["name = ?", name], :limit => 1 )
    if setting.value == "1"
      return true
    else # not true
      return false
    end
  rescue # ActiveRecord not found
    return false
  end
  
  def title
    return I18n.t("setting.title.#{self[:name].downcase}", :default => self[:title])
  end
  
  def description
    return I18n.t("setting.description.#{self[:name].downcase}", :default => self[:description])
  end
  
  def self.to_yaml # convert setting names to yaml for translations
    require "yaml"
    
    hash = Hash.new
    hash[:titles] = Hash.new 
    hash[:descriptions] = Hash.new
    for setting in Setting.find(:all)
      hash[:titles][setting.name.to_sym] = setting.title
      hash[:descriptions][setting.name.to_sym] = setting.description  
    end
    
    return YAML::dump hash
  end
  

end
