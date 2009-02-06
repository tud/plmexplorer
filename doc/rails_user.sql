--
-- Create rails account
--
drop user rails cascade;
create user rails
	identified by rails
	default tablespace DMS_DATA
	temporary tablespace DMS_TEMP
	quota unlimited on DMS_DATA
	quota unlimited on DMS_TEMP;

--
-- Grant all the required privileges
--
grant all privileges to rails with admin option;

exit
