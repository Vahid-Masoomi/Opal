class PluginFeature < ActiveRecord::Base
  # A Bullet is just the template of the bullet, users ONLY have control of the bullet value, The Admin adds the actual bullet template.
  # This is a special type of item object.
  has_many :plugin_feature_values
  has_many :plugin_feature_value_options  
  belongs_to :plugin
  belongs_to :user
  
  after_destroy :destroy_values

  validates_presence_of :name
  validates_numericality_of :min, :max, :allow_nil => true 

  def destroy_values # destroy all values for this feature
    for item in self.plugin_feature_values
      item.destroy
    end
    
    for item in self.plugin_feature_value_options
      item.destroy
    end    
  end

  def is_approved?
    return self.is_approved == "1"
  end
 
 
 def self.check(options = {}) # checks hash for presence of required features and feature value appropriateness
   options[:item]       ||= nil # item needed to add errors
   options[:features]   ||= Hash.new
   
   errors = Hash.new
   
   features = PluginFeature.find(:all)
   for feature in features
     entered_value = options[:features][feature.id.to_s]["value"]
     if entered_value && entered_value != "" # they entered a value for this feature
       if feature.feature_type == "number" || feature.feature_type == "slider"  # make sure they entered a number 
         if entered_value !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/ # is this a float?
           
           errors[feature.name] = "is not a number!"
         else # this is a number
           # Check if within range
           if feature.min # check if below min
              errors[feature.name] = "must be greater than #{feature.min}" if entered_value.to_f < feature.min  # add requirement error            
           end 
           
           if feature.max # check if above max
               errors[feature.name] = "must be less than #{feature.max}" if entered_value.to_f > feature.max  # add requirement error            
           end         
         end  
         

      end
     else # they did not enter a value for this feature
       if feature.is_required # this is a required feature?
             #options[:item].errors.add(required_feature.name, " is required!")
             errors[feature.name] = "is required!" # add requirement error
       end   
     end   
   end
   return errors
 end
 
 def self.create_values_for_item(options = {}) # create values for an item(from a hash)
   # Set defaults 
   options[:item]                   ||= nil
   options[:features]               ||= Hash.new
   options[:user]                   ||= nil # user making changes
   options[:approve] = true if !defined? options[:approve] # never use ||= for default values when the value is a bool
   options[:delete_existing] = true if !defined? options[:delete_existing_values] # never use ||= for default values when the value is a bool
     logger.info options.inspect

   counter = 0 # num of values saved
   
   options[:features].each do |feature_id, feature_value| 
     if options[:delete_existing] # delete any existing values
      existing_value = PluginFeatureValue.find(:first, :conditions => ["plugin_feature_id = ? and item_id = ?", feature_id, options[:item].id])
      existing_value.destroy if existing_value 
     end
    
     feature_value = PluginFeatureValue.new(feature_value) 
     # Handle protected attributes
     feature_value.plugin_feature_id =  feature_id     
     feature_value.item_id = options[:item].id     
     feature_value.user_id = options[:user].id          
     feature_value.is_approved = "1" if options[:approve] == true 
     
     counter += 1 if feature_value.save     
   end   
   return counter
 end
end
