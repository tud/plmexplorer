class ReportsController < ApplicationController

  before_filter :authorize

  require 'tempfile'

  def bomnew
    if request.post?
      brecord = params[:brecord]
      blank2star(brecord)
      brecname = "#{brecord[:report_rec_name]}&#{brecord[:report_rec_bname1]}"
      edm_report = Hash.new
      edm_report[:report] = 'OTO-BOMNEW'
      edm_report[:edm_p01] = "#{brecord[:report_rec_brectype]}\\#{brecname}\\#{brecord[:report_rec_brecalt]}"
      edm_report[:edm_p02] = brecord[:report_depth]
      edm_report[:edm_p03] = brecord[:report_data_maturity]
      edm_report[:edm_p04] = brecord[:report_alternate_language]
      edm_report[:edm_p05] = brecord[:report_record_type]
      edm_report[:edm_p06] = brecord[:report_print_header]
      edm_report[:edm_p07] = brecord[:report_separating_char]
      edm_report[:edm_p08] = ''
      submit edm_report
    end
    render :layout => false
  end
  
  def bomvalnew
    if request.post?
      brecord = params[:brecord]
      blank2star(brecord)
      part_brecname = "#{brecord[:report_rec_name]}&#{brecord[:report_rec_bname1]}"
      ei_brecname = "#{brecord[:report_ei_name]}&#{brecord[:report_ei_bname1]}"
      edm_report = Hash.new
      edm_report[:report] = 'OTO-BOMVALNEW'
      edm_report[:edm_p01] = "#{brecord[:report_rec_brectype]}\\#{part_brecname}\\#{brecord[:report_rec_brecalt]}"
      edm_report[:edm_p02] = "#{brecord[:report_rec_brectype]}\\#{ei_brecname}\\#"
      edm_report[:edm_p03] = brecord[:report_data_maturity]
      edm_report[:edm_p04] = brecord[:report_serial_number]
      edm_report[:edm_p05] = brecord[:report_record_type]
      edm_report[:edm_p06] = 'COMPLETO'
      edm_report[:edm_p07] = "#{brecord[:report_sort_criteria]} #{brecord[:report_depth]} #{brecord[:report_alternate_language]} #{brecord[:report_print_header]} #{brecord[:report_separating_char]}"
      edm_report[:edm_p08] = ''
      submit edm_report
    end
    render :layout => false
  end
  
  def ei
    if request.post?
      brecord = params[:brecord]
      blank2star(brecord)
      brecname = "#{brecord[:report_rec_name]}&#{brecord[:report_rec_bname1]}"
      edm_report = Hash.new
      edm_report[:report] = 'OTO-EI'
      edm_report[:edm_p01] = brecname
      edm_report[:edm_p02] = ''
      edm_report[:edm_p03] = ''
      edm_report[:edm_p04] = ''
      edm_report[:edm_p05] = ''
      edm_report[:edm_p06] = ''
      edm_report[:edm_p07] = ''
      edm_report[:edm_p08] = ''
      submit edm_report
    end
    render :layout => false
  end
  
  def odm
    if request.post?
      brecord = params[:brecord]
      blank2star(brecord)
      edm_report = Hash.new
      edm_report[:report] = 'OTO-ODM'
      edm_report[:edm_p01] = "#{brecord[:report_rec_brectype]}\\#{brecord[:report_rec1_name]}\\#{brecord[:report_rec1_brecalt]}"
      edm_report[:edm_p02] = "#{brecord[:report_rec_brectype]}\\#{brecord[:report_rec2_name]}\\#{brecord[:report_rec2_brecalt]}"
      edm_report[:edm_p03] = "#{brecord[:report_rec_breclevel]} #{brecord[:report_rec_bproject]} #{brecord[:report_rec_bowner]} Y"
      edm_report[:edm_p04] = "#{brecord[:report_rec_bname1]} NO_OTO_REQ"
      edm_report[:edm_p05] = "#{brecord[:report_rec_btype3]} #{brecord[:report_uda_change_subclass]} #{brecord[:report_serial_number]}"
      edm_report[:edm_p06] = "#{brecord[:report_rec_bpromdate_from]} #{brecord[:report_rec_bpromdate_to]}"
      edm_report[:edm_p07] = "#{brecord[:report_format]} TEXT #{brecord[:report_record_type]}"
      edm_report[:edm_p08] = ''
      submit edm_report
    end
    render :layout => false
  end
  
  def req
    if request.post?
      brecord = params[:brecord]
      blank2star(brecord)
      edm_report = Hash.new
      edm_report[:report] = 'OTO-REQ'
      edm_report[:edm_p01] = "#{brecord[:report_rec_brectype]}\\#{brecord[:report_rec1_name]}\\#{brecord[:report_rec1_brecalt]}"
      edm_report[:edm_p02] = "#{brecord[:report_rec_brectype]}\\#{brecord[:report_rec2_name]}\\#{brecord[:report_rec2_brecalt]}"
      edm_report[:edm_p03] = "#{brecord[:report_rec_breclevel]} #{brecord[:report_rec_bproject]} #{brecord[:report_rec_bowner]} N" 
      edm_report[:edm_p04] = "* #{brecord[:report_progress]}"
      edm_report[:edm_p05] = ''
      edm_report[:edm_p06] = "#{brecord[:report_rec_bpromdate_from]} #{brecord[:report_rec_bpromdate_to]}"
      edm_report[:edm_p07] = "#{brecord[:report_format]} TEXT REQUEST"
      edm_report[:edm_p08] = ''
      submit edm_report
    end
    render :layout => false
  end
  
  def wa
    if request.post?
      brecord = params[:brecord]
      blank2star(brecord)
      edm_report = Hash.new
      edm_report[:report] = 'OTO-WA'
      edm_report[:edm_p01] = "#{brecord[:report_rec_brectype]}\\#{brecord[:report_rec1_name]}\\#{brecord[:report_rec1_brecalt]}"
      edm_report[:edm_p02] = "#{brecord[:report_rec_brectype]}\\#{brecord[:report_rec2_name]}\\#{brecord[:report_rec2_brecalt]}"
      edm_report[:edm_p03] = "#{brecord[:report_rec_breclevel]} #{brecord[:report_rec_bproject]} #{brecord[:report_rec_bowner]} N"
      edm_report[:edm_p04] = "#{brecord[:report_rec_bname1]} NO_OTO_REQ"
      edm_report[:edm_p05] = "#{brecord[:report_rec_btype3]} #{brecord[:report_uda_change_subclass]} #{brecord[:report_serial_number]}"
      edm_report[:edm_p06] = "#{brecord[:report_rec_bpromdate_from]} #{brecord[:report_rec_bpromdate_to]}"
      edm_report[:edm_p07] = "#{brecord[:report_format]} TEXT #{brecord[:report_record_type]}"
      edm_report[:edm_p08] = ''
      submit edm_report
    end
    render :layout => false
  end
  

  private

  def blank2star(brecord)
    # Compila con un asterisco i campi vuoti
    fields = [
      :report_rec2_name,
      :report_ei_name,
      :report_rec_bname1,
      :report_ei_bname1,
      :report_rec_breclevel,
      :report_rec_bproject,
      :report_rec_bowner,
      :report_rec_btype3,
      :report_uda_change_subclass,
      :report_serial_number,
      :report_rec_bpromdate_from,
      :report_rec_bpromdate_to
    ]
    fields.each do |field|
      brecord[field] = '*' if brecord[field] && brecord[field] == ''
    end
  end

  def submit(edm_report)
    brecord = params[:brecord]
    edm_report[:edm_print_queue] = brecord[:report_print_queue]
    edm_report[:edm_output_file] = brecord[:report_output_file]
    logfile = Tempfile.new(edm_report[:report])
    if ENV['RAILS_ENV'] == 'development'
      # In sviluppo creo lo script DMS di lancio del report
      # in un file temporaneo
      script = logfile
    else
      # In produzione uso il file temporaneo come file di log
      # e creo una pipe verso una sessione DMS remota, cui sottometto
      # lo script di lancio del report
      logfile.close
      script = IO.popen("rsh #{PREF['SHERPA_SERVER']} dms > #{logfile.path}", "w")
    end
    script.puts("set db #{PREF['SHERPA_DB']}")
    script.puts("set user #{session[:user][:buser]}")
    script.puts("set project PIM")
    script.puts("update record EDM_REPORT\\#{edm_report[:report]};1")
    edm_report.each do |key, value|
      if key != :report
        script.puts "  change attribute #{key} \"#{value}\""
      end
    end
    script.puts("end update")
    script.puts("modify record EDM_REPORT\\#{edm_report[:report]}")
    script.puts("end modify")
    script.puts("exit")
    script.close
  end
end
