# RSI: implementation idea taken from JDBC adapter
if defined?(Rake.application) && Rake.application
  oracle_enhanced_rakefile = File.dirname(__FILE__) + "/oracle_enhanced.rake"
  if Rake.application.lookup("environment")
    # rails tasks already defined; load the override tasks now
    load oracle_enhanced_rakefile
  else
    # rails tasks not loaded yet; load as an import
    Rake.application.add_import(oracle_enhanced_rakefile)
  end
end
