require File.dirname(__FILE__) + '/../../spec_helper.rb'

describe "OracleEnhancedAdapter custom methods for create, update and destroy" do
  include LoggerSpecHelper
  
  before(:all) do
    ActiveRecord::Base.establish_connection(CONNECTION_PARAMS)
    @conn = ActiveRecord::Base.connection
    plsql.connection = ActiveRecord::Base.connection.raw_connection
    @conn.execute("DROP TABLE test_employees") rescue nil
    @conn.execute <<-SQL
      CREATE TABLE test_employees (
        employee_id   NUMBER(6,0),
        first_name    VARCHAR2(20),
        last_name     VARCHAR2(25),
        hire_date     DATE,
        salary        NUMBER(8,2),
        description   CLOB,
        version       NUMBER(15,0),
        create_time   DATE,
        update_time   DATE
      )
    SQL
    @conn.execute("DROP SEQUENCE test_employees_s") rescue nil
    @conn.execute <<-SQL
      CREATE SEQUENCE test_employees_s  MINVALUE 1
        INCREMENT BY 1 CACHE 20 NOORDER NOCYCLE
    SQL
    @conn.execute <<-SQL
      CREATE OR REPLACE PACKAGE test_employees_pkg IS
        PROCEDURE create_employee(
            p_first_name    VARCHAR2,
            p_last_name     VARCHAR2,
            p_hire_date     DATE,
            p_salary        NUMBER,
            p_description   VARCHAR2,
            p_employee_id   OUT NUMBER);
        PROCEDURE update_employee(
            p_employee_id   NUMBER,
            p_first_name    VARCHAR2,
            p_last_name     VARCHAR2,
            p_hire_date     DATE,
            p_salary        NUMBER,
            p_description   VARCHAR2);
        PROCEDURE delete_employee(
            p_employee_id   NUMBER);
      END;
    SQL
    @conn.execute <<-SQL
      CREATE OR REPLACE PACKAGE BODY test_employees_pkg IS
        PROCEDURE create_employee(
            p_first_name    VARCHAR2,
            p_last_name     VARCHAR2,
            p_hire_date     DATE,
            p_salary        NUMBER,
            p_description   VARCHAR2,
            p_employee_id   OUT NUMBER)
        IS
        BEGIN
          SELECT test_employees_s.NEXTVAL INTO p_employee_id FROM dual;
          INSERT INTO test_employees (employee_id, first_name, last_name, hire_date, salary, description,
                                      version, create_time, update_time)
          VALUES (p_employee_id, p_first_name, p_last_name, p_hire_date, p_salary, p_description,
                                      1, SYSDATE, SYSDATE);
        END create_employee;
        
        PROCEDURE update_employee(
            p_employee_id   NUMBER,
            p_first_name    VARCHAR2,
            p_last_name     VARCHAR2,
            p_hire_date     DATE,
            p_salary        NUMBER,
            p_description   VARCHAR2)
        IS
            v_version       NUMBER;
        BEGIN
          SELECT version INTO v_version FROM test_employees WHERE employee_id = p_employee_id FOR UPDATE;
          UPDATE test_employees
          SET employee_id = p_employee_id, first_name = p_first_name, last_name = p_last_name,
              hire_date = p_hire_date, salary = p_salary, description = p_description,
              version = v_version + 1, update_time = SYSDATE;
        END update_employee;
        
        PROCEDURE delete_employee(
            p_employee_id   NUMBER)
        IS
        BEGIN
          DELETE FROM test_employees WHERE employee_id = p_employee_id;
        END delete_employee;
      END;
    SQL

    ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.emulate_dates_by_column_name = true

    class ::TestEmployee < ActiveRecord::Base
      set_primary_key :employee_id
      
      validates_presence_of :first_name, :last_name, :hire_date
      
      # should return ID of new record
      set_create_method do
        plsql.test_employees_pkg.create_employee(
          :p_first_name => first_name,
          :p_last_name => last_name,
          :p_hire_date => hire_date,
          :p_salary => salary,
          :p_description => "#{first_name} #{last_name}",
          :p_employee_id => nil
        )[:p_employee_id]
      end

      # return value is ignored
      set_update_method do
        plsql.test_employees_pkg.update_employee(
          :p_employee_id => id,
          :p_first_name => first_name,
          :p_last_name => last_name,
          :p_hire_date => hire_date,
          :p_salary => salary,
          :p_description => "#{first_name} #{last_name}"
        )
      end

      # return value is ignored
      set_delete_method do
        plsql.test_employees_pkg.delete_employee(
          :p_employee_id => id
        )
      end

    end
  end
  
  after(:all) do
    Object.send(:remove_const, "TestEmployee")
    @conn = ActiveRecord::Base.connection    
    @conn.execute "DROP TABLE test_employees"
    @conn.execute "DROP SEQUENCE test_employees_s"
    @conn.execute "DROP PACKAGE test_employees_pkg"
  end

  before(:each) do
    @today = Date.new(2008,6,28)
    @buffer = StringIO.new
  end

  it "should create record" do
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    @employee.reload
    @employee.first_name.should == "First"
    @employee.last_name.should == "Last"
    @employee.hire_date.should == @today
    @employee.description.should == "First Last"
    @employee.create_time.should_not be_nil
    @employee.update_time.should_not be_nil
  end

  it "should rollback record when exception is raised in after_create callback" do
    @employee = TestEmployee.new(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    TestEmployee.class_eval { def after_create() raise "Make the transaction rollback" end }
    begin
      employees_count = TestEmployee.count
      @employee.save
      fail "Did not raise exception"
    rescue => e
      e.message.should == "Make the transaction rollback"
      @employee.id.should == nil
      TestEmployee.count.should == employees_count
    ensure
      TestEmployee.class_eval { remove_method :after_create }
    end
  end

  it "should update record" do
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today,
      :description => "description"
    )
    @employee.reload
    @employee.first_name = "Second"
    @employee.save!
    @employee.reload
    @employee.description.should == "Second Last"
  end

  it "should rollback record when exception is raised in after_update callback" do
    TestEmployee.class_eval { def after_update() raise "Make the transaction rollback" end }
    begin
      @employee = TestEmployee.create(
        :first_name => "First",
        :last_name => "Last",
        :hire_date => @today,
        :description => "description"
      )
      empl_id = @employee.id
      @employee.reload
      @employee.first_name = "Second"
      @employee.save!
      fail "Did not raise exception"
    rescue => e
      e.message.should == "Make the transaction rollback"
      @employee.reload
      @employee.first_name.should == "First"
    ensure
      TestEmployee.class_eval { remove_method :after_update }
    end
  end

  it "should not update record if nothing is changed and partial updates are enabled" do
    return pending("Not in this ActiveRecord version") unless TestEmployee.respond_to?(:partial_updates=)
    TestEmployee.partial_updates = true
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    @employee.reload
    @employee.save!
    @employee.reload
    @employee.version.should == 1
  end

  it "should update record if nothing is changed and partial updates are disabled" do
    return pending("Not in this ActiveRecord version") unless TestEmployee.respond_to?(:partial_updates=)
    TestEmployee.partial_updates = false
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    @employee.reload
    @employee.save!
    @employee.reload
    @employee.version.should == 2
  end

  it "should delete record" do
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    @employee.reload
    empl_id = @employee.id
    @employee.destroy
    @employee.should be_frozen
    TestEmployee.find_by_employee_id(empl_id).should be_nil
  end

  it "should rollback record when exception is raised in after_desotry callback" do
    TestEmployee.class_eval { def after_destroy() raise "Make the transaction rollback" end }
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    @employee.reload
    empl_id = @employee.id
    begin
      @employee.destroy
      fail "Did not raise exception"
    rescue => e
      e.message.should == "Make the transaction rollback"
      @employee.id.should == empl_id
      TestEmployee.find_by_employee_id(empl_id).should_not be_nil
    ensure
      TestEmployee.class_eval { remove_method :after_destroy }
    end
  end

  it "should log create record" do
    log_to @buffer
    # reestablish plsql.connection as log_to might reset existing connection
    plsql.connection = ActiveRecord::Base.connection.raw_connection
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    @buffer.string.should match(/^TestEmployee Create \(\d+\.\d+(ms)?\)  custom create method$/)
  end

  it "should log update record" do
    (TestEmployee.partial_updates = false) rescue nil
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    log_to @buffer
    # reestablish plsql.connection as log_to might reset existing connection
    plsql.connection = ActiveRecord::Base.connection.raw_connection
    @employee.save!
    @buffer.string.should match(/^TestEmployee Update \(\d+\.\d+(ms)?\)  custom update method with employee_id=#{@employee.id}$/)
  end

  it "should log delete record" do
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    log_to @buffer
    # reestablish plsql.connection as log_to might reset existing connection
    plsql.connection = ActiveRecord::Base.connection.raw_connection
    @employee.destroy
    @buffer.string.should match(/^TestEmployee Destroy \(\d+\.\d+(ms)?\)  custom delete method with employee_id=#{@employee.id}$/)
  end

  it "should validate new record before creation" do
    @employee = TestEmployee.new(
      :last_name => "Last",
      :hire_date => @today
    )
    @employee.save.should be_false
    @employee.errors.on(:first_name).should_not be_nil
  end

  it "should validate existing record before update" do
    @employee = TestEmployee.create(
      :first_name => "First",
      :last_name => "Last",
      :hire_date => @today
    )
    @employee.first_name = nil
    @employee.save.should be_false
    @employee.errors.on(:first_name).should_not be_nil
  end
  
end
