class PluginTag < ActiveRecord::Base
  belongs_to :plugin
  belongs_to :item
  belongs_to :user

  validates_presence_of :name 
  validates_length_of :name, :minimum => 1
  validates_format_of :name, :with => /^[a-zA-Z0-9][^\.\?&=\s]*$/  # make url safe.
  
  def is_approved?
     if self.is_approved == "1"
       return true
     else # not approved
       return false
     end
  end
end
