.. _maximum_binlog_files:

========================================
 Restricting the number of binlog files
========================================

Maximum number of binlog files can now be restricted in |Percona Server| with :variable:`max_binlog_files`. When variable :variable:`max_binlog_files` is set to non-zero value, the server will remove the oldest binlog file(s) whenever their number exceeds the value of the variable. 

This variable can be used with the existing :variable:`max_binlog_size` variable to limit the disk usage of the binlog files. If :variable:`max_binlog_size` is set to 1G and :variable:`max_binlog_files` to 20 this will limit the maximum size of the binlogs on disk to 20G. The actual size limit is not necessarily :variable:`max_binlog_size` * :variable:`max_binlog_files`. Server restart or ``FLUSH LOGS`` will make the server start a new log file and thus resulting in log files that are not fully written in these cases limit will be lower. 

Version Specific Information
============================

  * 5.5.27-29.0:
    Variable :variable:`max_binlog_files` introduced.

System Variables
================

.. variable:: max_binlog_files

     :version 5.5.27-29.0: Introduced.
     :cli: Yes
     :conf: Yes
     :scope: Global
     :dyn: Yes
     :vartype: ULONG
     :default: 0 (unlimited)
     :range: 0-102400

Example
=======

Number of the binlog files before setting this variable :: 

  $ ls -l mysql-bin.0* | wc -l
  26

Variable :variable:`max_binlog_files` is set to 20: ::

  max_binlog_files = 20

In order for new value to take effect ``FLUSH LOGS`` needs to be run. After that the number of binlog files is 20 :: 

  $ ls -l mysql-bin.0* | wc -l
  20

