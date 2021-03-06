class User < ActiveRecord::Base
  require 'digest/sha2'
  #Relationships
  has_many :items
  has_many :user_messages
  has_many :pages
  has_many :page_comments
  has_one :user_info
  has_many :user_verifications
  has_many :logs
  belongs_to :group
  
  #-------------validations-----------------------
  validates_uniqueness_of :username #this will comb through the database and make sure email is unique
  validates_uniqueness_of :email #this will comb through the database and make sure email is unique
  validates_presence_of :username, :first_name, :last_name, :email
  validates_confirmation_of :password # this will confirm the password, but you have to have an html input called password_confirmation
  validates_length_of :username, :maximum => 255
  #validates_numericality_of :zip
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  
  
  #-----------------------------------------------
  before_save :strip_html
  after_create :create_everything
  after_destroy :destroy_everything
  
  
  # Enable Authlogic
  acts_as_authentic do |c| 
    c.validate_email_field     = false
    c.validate_login_field     = false
    c.validate_password_field  = false
  end
  
  #------------Login Authentication---------------
  def self.authenticate(login, unhashed_pass)
    u = self.find(:first, :conditions => ["username = ? and password_hash = ?", login, Digest::SHA256.hexdigest(unhashed_pass) ] )# check username column with the hashed pass arg
    if u 
      return u.id
    else
      nil
    end
  end  
  #----------------------------------------------- 
  
  attr_accessor :password_confirmation, :password # virtual attributes
  attr_protected :is_admin, :is_verified, :is_disabled # protect from bulk assignment
  
  #--------Encrypt Password-------------------------
  # make sure you're doing attr_accessor before this
  def password=(pass)
    @password = pass 
    self.password_hash = Digest::SHA256.hexdigest(pass)
  end
  #-------------------------------------------------
  
  def valid_password?(password) # check if this password is the user's password
   self.password_hash == Digest::SHA256.hexdigest(password)
  end
  
  def self.search(search, page)
    paginate :per_page => 5, :page => page,
             :conditions => ['username like ?', "%#{search}%"],
             :order => 'username'
  end
  # call with @products = Product.search(params[:search], params[:page])
  #------------------------------------------------- 

  def to_param # make custom parameter generator for seo urls, to use: pass actual object(not id) into id ie: :id => object
    # this is also backwards compatible with id lookups, since .to_i gets only contiguous numbers, ie: "4-some-string-here".to_i # => 4    
    "#{id}-#{username.parameterize}" 
  end
  
  def to_s
    self.username
  end
  
  def is_admin? 
   if self.is_admin == "1" || self.group.is_admin_group?
    return true
   else 
    return false
   end
  end
  
  def destroy_everything
    avatars_path = "#{Rails.root.to_s}/public/images/avatars"
    avatar_path = "#{avatars_path}/#{self.id}.png"
    if File.exists?(avatar_path) # check if avatar exists
      FileUtils.rm(avatar_path) # delete!
    end
    
    for item in self.items
      item.destroy
    end
  
    self.user_info.destroy if self.user_info # delete user info(descriptions, avatar, etc.)
    
    for item in self.user_messages # delete messages
      item.destroy 
    end
    
    #for item in UserMessage.messages_from_user(self) # delete messages from user
      #item.destroy 
    #end    
    
    for item in self.pages # delete pages
      item.destroy 
    end

    page_comments = PageComment.find(:all, :conditions => ["user_id = ?", self.id] )
    for item in page_comments # delete all page comments
      item.destroy 
    end      
    
    for item in self.user_verifications # delete verification emails
      item.destroy 
    end  
    
    reviews = PluginReview.find(:all, :conditions => ["user_id = ?", self.id] )
    for item in reviews # delete reviews
      item.destroy 
    end   
    
    comments = PluginComment.find(:all, :conditions => ["user_id = ?", self.id] )
    for item in comments # delete comments
      item.destroy 
    end  
    
    discussion_posts = PluginDiscussionPost.find(:all, :conditions => ["user_id = ?", self.id] )
    for item in discussion_posts # delete comments
      item.destroy 
    end    

    for item in PluginDescription.find(:all, :conditions => ["user_id = ?", self.id] )# delete descriptions
      item.destroy 
    end       
  end
  
  def create_everything
    # Dave: This is called after a user account is created. Makes Public Info, etc.
    user_info = UserInfo.new(:description => "No Description.")
    user_info.user_id = self.id
    user_info.save    
  end

 def strip_html # Automatically strips any tags from any string to text typed column
    for column in User.content_columns
      if column.type == :string || column.type == :text # if the column is a sql string or text
        self[column.name] = self[column.name].gsub(/<\/?[^>]*>/, "")  if !self[column.name].nil? # strip html from string
      end
    end
 end

  def use_gravatar?
    self.user_info ? self.user_info.use_gravatar == "1" : false
  end

  def is_enabled?
    if self.is_disabled == "1" 
      return false
    else 
      return true
    end    
  end

  def is_verified?
    if self.is_verified == "1" || self.is_admin? # you don't have to be verified if you're an admin.
      return true
    else 
      return false
    end      
  end
  
  def self.admins # get all admins
    return User.find(:all, :conditions => ["is_verified = '1' and is_disabled = '0' and is_admin = '1'"])
  end
  
  def anonymous? # is the user an anonymous user?
    (self.id == 0 || self.id.nil?)   
  end
  
  def self.anonymous # generate anonymous user
    u = User.new(:username => "Guest", :first_name => "No", :last_name => "Name")
    u.id = 0       
    u.group_id = 1 # set for public group
    u.locale = Setting.global_settings[:locale] # set system default locale
    return u     
  end
  
end
