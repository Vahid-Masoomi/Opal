class PluginDescription < ActiveRecord::Base
  belongs_to :plugin
  belongs_to :item
  belongs_to :user

  def is_approved?
     if self.is_approved == "1"
       return true
     else # not approved
       return false
     end
  end
end
