class Bfile < ActiveRecord::Base
  belongs_to :brecord,  :foreign_key => 'bobjid'

  include ActionView::Helpers::NumberHelper

  def storage
    @storage ||= Bstorage.find_by_bname(bstorage)
  end

  def path
    if storage.open?
      filename = bunixalias
    else
      filename = bid
    end
    "#{PREF['STORAGE_PATH'][ENV['RAILS_ENV']]}/#{bstorage}/#{filename}.#{'%05d' % bversion}"
  end

  def name
    bunixalias
  end
  
  def format
    bunixalias[-3..-1].downcase
  end

  def size
    begin
      number_to_human_size(File.size(path))
    rescue
      MSG['NO_FILE']
    end
  end

end
