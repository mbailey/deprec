create database <%= @username %>_prod;
GRANT USAGE ON *.* TO '<%= @username %>_db'@'%';

GRANT ALL PRIVILEGES 
ON <%= @username %>_prod.*
TO <%= @username %>_db@'%'
IDENTIFIED BY '<%= @mysqlpass %>';

FLUSH PRIVILEGES;


create database <%= @username %>_stage;
GRANT USAGE ON *.* TO '<%= @username %>_db'@'%';

GRANT ALL PRIVILEGES 
ON <%= @username %>_stage.*
TO <%= @username %>_db@'%'
IDENTIFIED BY '<%= @mysqlpass %>';

FLUSH PRIVILEGES;
