class Thing < ActiveRecord::Base
  belongs_to :user

  def self.cache_key
    Digest::SHA2.hexdigest all.map(&:cache_key).join
  end

end
