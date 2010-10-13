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

# == Schema Information
#
# Table name: bfiles
#
#  bobjid        :integer(10)
#  brellevel     :string(16)
#  blevelid      :integer(5)
#  balias        :string(32)
#  bvmsalias     :string(128)
#  bunixalias    :string(128)
#  bdosalias     :string(12)
#  bntalias      :string(128)
#  bmacalias     :string(31)
#  bsource       :string(255)
#  bfiledate     :datetime
#  bstatus       :string(8)
#  bid           :string(32)
#  bversion      :integer(5)
#  bstorage      :string(16)
#  bviewmode     :string(7)
#  bsyncflag     :string(3)
#  bdesc         :string(80)
#  btype1        :string(16)
#  btype2        :string(16)
#  bname1        :string(32)
#  bname2        :string(32)
#  blong1        :integer(10)
#  blong2        :integer(10)
#  bdate1        :datetime
#  bdate2        :datetime
#  bdouble1      :decimal(, )
#  bdouble2      :decimal(, )
#  bformat       :string(16)
#  bsourcetool   :string(16)
#  bcreateuser   :string(16)
#  created_at    :datetime
#  boutdate      :datetime
#  bcompressflag :string(3)
#  bcompressutil :string(255)
#  bfiledbid     :string(2)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

