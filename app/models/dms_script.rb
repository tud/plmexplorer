require 'fileutils'
require 'tempfile'

class DmsScript < Tempfile

  CHANGE_ATTRIBUTES = [ :bdesc, :bowner, :bproject, :brelproc, :btype1, :btype2, :btype3, :btype4, :bname1, :bname2, :bname3, :bname4, :bdate1, :bdate2, :bdate3, :bdate4, :blong1, :blong2, :blong3, :blong4, :bdouble1, :bdouble2, :bdouble3, :bdouble4, :bdouble5, :bdouble6, :bdouble7, :bdouble8, :bcost, :bfamily, :bbegindate, :benddate, :bmeasure ]

  def initialize(user, brecord)
    super('pex.dms.', PREF['LOCAL_SHARE'][ENV['RAILS_ENV']])
    puts("set db #{PREF['SHERPA_DB'][ENV['RAILS_ENV']]}")
    puts("set user #{user}")
    @brecord = brecord
    @brecord[:brectype].upcase!
    @brecord[:brecname].upcase!
  end

  def create_record(autonumber)
    # curr_brecord valorizzato solo in caso di modify!
    # In caso di create, si crea un'istanza vuota.
    @curr_brecord = Brecord.new

    # Genero codice ed incremento campo Autonumber, se usato
    if autonumber
      @brecord[:brecname] = Brecord.find_by_brectype_and_brecname('PIM_AUTONUM', @brecord[:brectype]).bdesc
      puts("modify record PIM_AUTONUM\\#{@brecord[:brectype]}")
      puts "  change attribute DESC \"#{@brecord[:brecname].to_i + 1}\""
      puts("end modify")
    end

    puts "create record #{@brecord.recspec}"
    yield
    puts "end create"
  end

  def modify_record
    # Inizializzo curr_brecord con lo stato attuale del record da modificare.
    # Serve a stabilire cosa cambia effettivamente.
    brecalt = @brecord[:brecalt].to_s.upcase
    # Il recalt vuoto corrisponde a brecalt = blank nel DB!
    brecalt = ' ' if brecalt.empty?
    @curr_brecord = Brecord.find_by_brectype_and_brecname_and_brecalt(@brecord[:brectype], @brecord[:brecname], brecalt,
                                                                      :conditions => "id = blatest")
    puts "modify record #{@brecord.recspec}"
    yield
    puts "end modify"
  end

  def approve_record(level_name, chk_name, comment = '')
    puts "mark record #{@brecord.recspec} #{level_name} #{chk_name} \"#{escape(comment)}\""
  end

  def promote_record(level_name, comment = '')
    puts "promote record #{@brecord.recspec} #{level_name} \"#{escape(comment)}\""
  end

  def change_attributes
    CHANGE_ATTRIBUTES.each do |attr|
      if @brecord[attr]
        puts "  change attribute #{attr.to_s.upcase[1..-1]} \"#{escape(@brecord[attr])}\""
      end
    end
    @brecord.budas.each do |uda|
      puts_uda(uda[:bname], uda[:bvalue])
    end
  end

  def add_files
    @brecord.bfiles.each do |file|
      file_alias = File.basename(file[:upload].original_filename).gsub(/ /,'_')[0..31]
      upload_name = File.basename(file[:upload].path)
      FileUtils.copy(file[:upload].path, PREF['LOCAL_SHARE'][ENV['RAILS_ENV']])
      remote_dest = File.join(PREF['REMOTE_SHARE'][ENV['RAILS_ENV']], upload_name)
      if @curr_brecord.file(file_alias)
        puts "  remove file #{file_alias}"
      end
      puts "  move file /secure \"#{remote_dest}\" #{file_alias}"
    end
  end

  def run
    puts("exit")
    close
    remote_path = File.join(PREF['REMOTE_SHARE'][ENV['RAILS_ENV']], File.basename(path))
    command = "rsh #{PREF['SHERPA_SERVER'][ENV['RAILS_ENV']]} -n -l #{PREF['SHERPA_USER'][ENV['RAILS_ENV']]} dms #{remote_path}"
    begin
      pipe = IO.popen(command, "w+")
      pipe.close_write
      # Scarta intestazione Sherpa/DMS ed "exit" finale dal log
      log = pipe.readlines[7..-2]
      pipe.close_read
      # Aggiorna il record, che puo' essere stato modificato!
      @brecord.reload if @brecord.id

      Rails.logger.info log
      errors = log.collect { |line| line[/^%DMS-E-.*/] }.compact
      if !errors.empty?
        @brecord.dms_errorlog = log
      end
    rescue
      @brecord.dms_errorlog = MSG['CONN_KO']
    end
  end


  private

  def puts_uda(name, value)
    if @curr_brecord.uda(name).strip != value
       puts "  change attribute #{name.upcase} \"#{value}\""
    end
  end

  # Raddoppio del doppio apice per le stringhe di Sherpa/DMS
  def escape(value)
    value.gsub(/"/,'""')
  end

end
