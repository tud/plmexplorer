class ReportsController < ApplicationController

  before_filter :authorize

  require 'tempfile'

  def bomnew
    if request.post?
      brecord = params[:brecord]
      if brecord[:report_rec_bname1] == ''
        # Senza Cage Code
        brecname = brecord[:report_rec_name]
      else
        # Con Cage Code
        brecname = "#{brecord[:report_rec_name]}&#{brecord[:report_rec_bname1]}"
      end
      edm_report = Hash.new
      edm_report[:report] = 'OTO-BOMNEW'
      edm_report[:edm_p01] = "#{brecord[:report_rec_brectype]}\\#{brecname}\\#{brecord[:report_rec_brecalt]}"
      edm_report[:edm_p02] = brecord[:report_level]
      edm_report[:edm_p03] = brecord[:report_data_maturity]
      edm_report[:edm_p04] = brecord[:report_alternate_language]
      edm_report[:edm_p05] = brecord[:report_record_type]
      edm_report[:edm_p06] = brecord[:report_print_header]
      edm_report[:edm_p07] = brecord[:report_separating_char]
      edm_report[:edm_p08] = ''
      edm_report[:edm_print_queue] = brecord[:report_print_queue]
      edm_report[:edm_output_file] = brecord[:report_output_file]
      submit edm_report
    end
    render :layout => false
  end
  
  def bomvalnew
    render :layout => false
  end
  
  def ei
    if request.post?
      brecord = params[:brecord]
      if brecord[:report_rec_bname1] == ''
        # Senza Cage Code
        brecname = brecord[:report_rec_name]
      else
        # Con Cage Code
        brecname = "#{brecord[:report_rec_name]}&#{brecord[:report_rec_bname1]}"
      end
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
      edm_report[:edm_print_queue] = brecord[:report_print_queue]
      edm_report[:edm_output_file] = brecord[:report_output_file]
      submit edm_report
    end
    render :layout => false
  end
  
  def odm
    render :layout => false
  end
  
  def req
    render :layout => false
  end
  
  def wa
    render :layout => false
  end
  

  private

  def submit(edm_report)
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
