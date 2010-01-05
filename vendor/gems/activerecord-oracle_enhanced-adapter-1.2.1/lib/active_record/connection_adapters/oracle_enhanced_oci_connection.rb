require 'delegate'

begin
  require 'oci8' unless self.class.const_defined? :OCI8

  # RSI: added mapping for TIMESTAMP / WITH TIME ZONE / LOCAL TIME ZONE types
  # currently Ruby-OCI8 does not support fractional seconds for timestamps
  OCI8::BindType::Mapping[OCI8::SQLT_TIMESTAMP] = OCI8::BindType::OraDate
  OCI8::BindType::Mapping[OCI8::SQLT_TIMESTAMP_TZ] = OCI8::BindType::OraDate
  OCI8::BindType::Mapping[OCI8::SQLT_TIMESTAMP_LTZ] = OCI8::BindType::OraDate
rescue LoadError
  # OCI8 driver is unavailable.
  error_message = "ERROR: ActiveRecord oracle_enhanced adapter could not load ruby-oci8 library. "+
                  "Please install ruby-oci8 library or gem."
  if defined?(RAILS_DEFAULT_LOGGER)
    RAILS_DEFAULT_LOGGER.error error_message
  else
    STDERR.puts error_message
  end
  raise LoadError
end

module ActiveRecord
  module ConnectionAdapters

    # OCI database interface for MRI
    class OracleEnhancedOCIConnection < OracleEnhancedConnection

      def initialize(config)
        @raw_connection = OCI8EnhancedAutoRecover.new(config, OracleEnhancedOCIFactory)
      end

      def auto_retry
        @raw_connection.auto_retry if @raw_connection
      end

      def auto_retry=(value)
        @raw_connection.auto_retry = value if @raw_connection
      end

      def logoff
        @raw_connection.logoff
        @raw_connection.active = false
      end

      def commit
        @raw_connection.commit
      end

      def rollback
        @raw_connection.rollback
      end

      def autocommit?
        @raw_connection.autocommit?
      end

      def autocommit=(value)
        @raw_connection.autocommit = value
      end

      # Checks connection, returns true if active. Note that ping actively
      # checks the connection, while #active? simply returns the last
      # known state.
      def ping
        @raw_connection.ping
      rescue OCIException => e
        raise OracleEnhancedConnectionException, e.message
      end

      def active?
        @raw_connection.active?
      end

      def reset!
        @raw_connection.reset!
      rescue OCIException => e
        raise OracleEnhancedConnectionException, e.message
      end

      def exec(sql, *bindvars, &block)
        @raw_connection.exec(sql, *bindvars, &block)
      end

      def select(sql, name = nil, return_column_names = false)
        cursor = @raw_connection.exec(sql)
        cols = []
        # Ignore raw_rnum_ which is used to simulate LIMIT and OFFSET
        cursor.get_col_names.each do |col_name|
          col_name = oracle_downcase(col_name)
          cols << col_name unless col_name == 'raw_rnum_'
        end
        # Reuse the same hash for all rows
        column_hash = {}
        cols.each {|c| column_hash[c] = nil}
        rows = []
        get_lob_value = !(name == 'Writable Large Object')

        while row = cursor.fetch
          hash = column_hash.dup

          cols.each_with_index do |col, i|
            hash[col] =
              case v = row[i]
              # RSI: added emulate_integers_by_column_name functionality
              when Float
                # if OracleEnhancedAdapter.emulate_integers_by_column_name && OracleEnhancedAdapter.is_integer_column?(col)
                #   v.to_i
                # else
                #   v
                # end
                v == (v_to_i = v.to_i) ? v_to_i : v
              # ruby-oci8 2.0 returns OraNumber - convert it to Integer or BigDecimal
              when OraNumber
                v == (v_to_i = v.to_i) ? v_to_i : BigDecimal.new(v.to_s)
              when String
                v
              when OCI8::LOB
                if get_lob_value
                  data = v.read
                  # In Ruby 1.9.1 always change encoding to ASCII-8BIT for binaries
                  data.force_encoding('ASCII-8BIT') if data.respond_to?(:force_encoding) && v.is_a?(OCI8::BLOB)
                  data
                else
                  v
                end
              # ruby-oci8 1.0 returns OraDate
              when OraDate
                # RSI: added emulate_dates_by_column_name functionality
                if OracleEnhancedAdapter.emulate_dates && (v.hour == 0 && v.minute == 0 && v.second == 0)
                  v.to_date
                else
                  # code from Time.time_with_datetime_fallback
                  begin
                    Time.send(Base.default_timezone, v.year, v.month, v.day, v.hour, v.minute, v.second)
                  rescue
                    offset = Base.default_timezone.to_sym == :local ? ::DateTime.local_offset : 0
                    ::DateTime.civil(v.year, v.month, v.day, v.hour, v.minute, v.second, offset)
                  end
                end
              # ruby-oci8 2.0 returns Time or DateTime
              when Time, DateTime
                if OracleEnhancedAdapter.emulate_dates && (v.hour == 0 && v.min == 0 && v.sec == 0)
                  v.to_date
                else
                  # recreate Time or DateTime using Base.default_timezone
                  begin
                    Time.send(Base.default_timezone, v.year, v.month, v.day, v.hour, v.min, v.sec)
                  rescue
                    offset = Base.default_timezone.to_sym == :local ? ::DateTime.local_offset : 0
                    ::DateTime.civil(v.year, v.month, v.day, v.hour, v.min, v.sec, offset)
                  end
                end
              else v
              end
          end

          rows << hash
        end

        return_column_names ? [rows, cols] : rows
      ensure
        cursor.close if cursor
      end

      def write_lob(lob, value, is_binary = false)
        lob.write value
      end
      
      def describe(name)
        quoted_name = OracleEnhancedAdapter.valid_table_name?(name) ? name : "\"#{name}\""
        @raw_connection.describe(quoted_name)
      rescue OCIException => e
        raise OracleEnhancedConnectionException, e.message
      end
      
    end
    
    # The OracleEnhancedOCIFactory factors out the code necessary to connect and
    # configure an Oracle/OCI connection.
    class OracleEnhancedOCIFactory #:nodoc:
      def self.new_connection(config)
        username, password, database = config[:username].to_s, config[:password].to_s, config[:database].to_s
        privilege = config[:privilege] && config[:privilege].to_sym
        async = config[:allow_concurrency]
        prefetch_rows = config[:prefetch_rows] || 100
        cursor_sharing = config[:cursor_sharing] || 'similar'

        conn = OCI8.new username, password, database, privilege
        conn.exec %q{alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS'}
        conn.exec %q{alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS'} rescue nil
        conn.autocommit = true
        conn.non_blocking = true if async
        conn.prefetch_rows = prefetch_rows
        conn.exec "alter session set cursor_sharing = #{cursor_sharing}" rescue nil
        conn
      end
    end
    
    
  end
end



class OCI8 #:nodoc:

  class Cursor #:nodoc:
    if method_defined? :define_a_column
      # This OCI8 patch is required with the ruby-oci8 1.0.x or lower.
      # Set OCI8::BindType::Mapping[] to change the column type
      # when using ruby-oci8 2.0.

      alias :enhanced_define_a_column_pre_ar :define_a_column
      def define_a_column(i)
        case do_ocicall(@ctx) { @parms[i - 1].attrGet(OCI_ATTR_DATA_TYPE) }
        when 8;   @stmt.defineByPos(i, String, 65535) # Read LONG values
        when 187; @stmt.defineByPos(i, OraDate) # Read TIMESTAMP values
        when 108
          if @parms[i - 1].attrGet(OCI_ATTR_TYPE_NAME) == 'XMLTYPE'
            @stmt.defineByPos(i, String, 65535)
          else
            raise 'unsupported datatype'
          end
        else enhanced_define_a_column_pre_ar i
        end
      end
    end
  end

  if OCI8.public_method_defined?(:describe_table)
    # ruby-oci8 2.0 or upper

    def describe(name)
      info = describe_table(name.to_s)
      raise %Q{"DESC #{name}" failed} if info.nil?
      [info.obj_schema, info.obj_name]
    end
  else
    # ruby-oci8 1.0.x or lower

    # missing constant from oci8 < 0.1.14
    OCI_PTYPE_UNK = 0 unless defined?(OCI_PTYPE_UNK)

    # Uses the describeAny OCI call to find the target owner and table_name
    # indicated by +name+, parsing through synonynms as necessary. Returns
    # an array of [owner, table_name].
    def describe(name)
      @desc ||= @@env.alloc(OCIDescribe)
      @desc.attrSet(OCI_ATTR_DESC_PUBLIC, -1) if VERSION >= '0.1.14'
      do_ocicall(@ctx) { @desc.describeAny(@svc, name.to_s, OCI_PTYPE_UNK) } rescue raise %Q{"DESC #{name}" failed; does it exist?}
      info = @desc.attrGet(OCI_ATTR_PARAM)

      case info.attrGet(OCI_ATTR_PTYPE)
      when OCI_PTYPE_TABLE, OCI_PTYPE_VIEW
        owner      = info.attrGet(OCI_ATTR_OBJ_SCHEMA)
        table_name = info.attrGet(OCI_ATTR_OBJ_NAME)
        [owner, table_name]
      when OCI_PTYPE_SYN
        schema = info.attrGet(OCI_ATTR_SCHEMA_NAME)
        name   = info.attrGet(OCI_ATTR_NAME)
        describe(schema + '.' + name)
      else raise %Q{"DESC #{name}" failed; not a table or view.}
      end
    end
  end

end

# The OCI8AutoRecover class enhances the OCI8 driver with auto-recover and
# reset functionality. If a call to #exec fails, and autocommit is turned on
# (ie., we're not in the middle of a longer transaction), it will
# automatically reconnect and try again. If autocommit is turned off,
# this would be dangerous (as the earlier part of the implied transaction
# may have failed silently if the connection died) -- so instead the
# connection is marked as dead, to be reconnected on it's next use.
class OCI8EnhancedAutoRecover < DelegateClass(OCI8) #:nodoc:
  attr_accessor :active
  alias :active? :active

  cattr_accessor :auto_retry
  class << self
    alias :auto_retry? :auto_retry
  end
  @@auto_retry = false

  def initialize(config, factory)
    @active = true
    @config = config
    @factory = factory
    @connection  = @factory.new_connection @config
    super @connection
  end

  # Checks connection, returns true if active. Note that ping actively
  # checks the connection, while #active? simply returns the last
  # known state.
  def ping
    @connection.exec("select 1 from dual") { |r| nil }
    @active = true
  rescue
    @active = false
    raise
  end

  # Resets connection, by logging off and creating a new connection.
  def reset!
    logoff rescue nil
    begin
      @connection = @factory.new_connection @config
      __setobj__ @connection
      @active = true
    rescue
      @active = false
      raise
    end
  end

  # ORA-00028: your session has been killed
  # ORA-01012: not logged on
  # ORA-03113: end-of-file on communication channel
  # ORA-03114: not connected to ORACLE
  # ORA-03135: connection lost contact
  LOST_CONNECTION_ERROR_CODES = [ 28, 1012, 3113, 3114, 3135 ]

  # Adds auto-recovery functionality.
  #
  # See: http://www.jiubao.org/ruby-oci8/api.en.html#label-11
  def exec(sql, *bindvars, &block)
    should_retry = self.class.auto_retry? && autocommit?

    begin
      @connection.exec(sql, *bindvars, &block)
    rescue OCIException => e
      raise unless LOST_CONNECTION_ERROR_CODES.include?(e.code)
      @active = false
      raise unless should_retry
      should_retry = false
      reset! rescue nil
      retry
    end
  end

  # RSI: otherwise not working in Ruby 1.9.1
  if RUBY_VERSION =~ /^1\.9/
    def describe(name)
      @connection.describe(name)
    end
  end

end
