# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090321012157) do

# Could not dump table "sessions" because of following ActiveRecord::StatementInvalid
#   OCIError: ORA-00904: nome di colonna non valido:             SELECT lower(i.index_name) as index_name, i.uniqueness, lower(c.column_name) as column_name
              FROM all_indexes i, user_ind_columns c
             WHERE i.table_name = 'SESSIONS'
               AND c.index_name = i.index_name
               AND i.index_name NOT IN (SELECT uc.index_name FROM user_constraints uc WHERE uc.constraint_type = 'P')
               AND i.owner = sys_context('userenv','session_user')
              ORDER BY i.index_name, c.column_position

end
