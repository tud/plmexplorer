class Bfile < ActiveRecord::Base
  belongs_to :brecord,  :foreign_key => 'bobjid'

  def storage
    @storage ||= Bstorage.find_by_bname(bstorage)
  end

  def path
    if storage.open?
      filename = bunixalias
    else
      filename = bid
    end
    "#{PREFS['STORAGE_PATH']}/#{bstorage}/#{filename}.#{'%05d' % bversion}"
  end

  def name
    bunixalias
  end

end
