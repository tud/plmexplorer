class Bfile < ActiveRecord::Base
  belongs_to :brecord,  :foreign_key => 'bobjid'

  UNITS = { :B => 1, :KB => 2**10, :MB => 2**20, :GB => 2**30 }

  def storage
    @storage ||= Bstorage.find_by_bname(bstorage)
  end

  def path
    if storage.open?
      filename = bunixalias
    else
      filename = bid
    end
    "#{PREF['STORAGE_PATH']}/#{bstorage}/#{filename}.#{'%05d' % bversion}"
  end

  def name
    bunixalias
  end
  
  def format
    bunixalias[-3..-1].downcase
  end

  def size
    begin
      bytes = File.size(path)
      if bytes >= UNITS[:GB]
        unit = :GB
      elsif bytes >= UNITS[:MB]
        unit = :MB
      elsif bytes >= UNITS[:KB]
        unit = :KB
      else
        unit = :B
      end
      "#{bytes / UNITS[unit]} #{unit}"
    rescue
      MSG['NO_FILE']
    end
  end

end
