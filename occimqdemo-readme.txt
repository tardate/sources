# ============================================================
# Notes on the OCCI MQ Demo
#
# See http://tardate.blogspot.com/2007/06/mq-and-occi-demo.html
# Prepared by Paul Gallagher <gallagher.paul@gmail.com>
# $Id: occimqdemo-readme.txt,v 1.5 2007/06/09 02:38:02 paulg Exp $
# ============================================================

What this sample demonstrates:
 1. C++ (OCCI) Oracle database access
 2. Transparent Application Failover (TAF) notifications in C++ (OCCI)
 3. Building a C++ application with MQ and OCCI support

What this sample does NOT demonstrate:
 1. MQ + DB operations within a single distributed transaction

Platform:
 1. Code is written to run on Linux x86. See the make file for a hint on how this can be easily adapted to 64bit Linux (e.g. ZSeries Linux 64)
 2. Requires Websphere MQ 6.0 for Linux (free download from IBM)
 3. Requires Oracle Database (free download from Oracle). Works with either full client or Instant Client.


For More Information
==============================================================================
See http://tardate.blogspot.com/2007/06/mq-and-occi-demo.html for more
description of the demo and access to the latest demo download.

For information on programming OCCI, see the OCCI home page on OTN
http://www.oracle.com/technology/tech/oci/occi/index.html

For more information about Oracle Database, see
http://www.oracle.com/technology/documentation/database10gr2.html


Overview of the Basic Flow to run this Demo
==============================================================================
The following sections are included in this file.

1. Check Current Limitations/Untested Aspects

2. Obtain and Install Oracle Database 10g

3. Obtain and Install Websphere MQ

4. setup the mqm user for Oracle

5. Setting up ORACLE tnsnames.ora

6. Setting up MQ OCCIMQDEMO environment

7. Build the OCCIMQDEMO sample programs
   7a. Initialising ORACLE OCCIMQDEMO schema for the demo
   7b. Build the C++ sample programs
   7c. Verifying Correct Build Libraries for OCCI

8. Running the demo

9. Generate a Test Report

10. Checking Queue Status

Assuming Oracle Database and MQ already installed, the commands for a full
build/test cycle are as follows:

	./qcontrol.sh initqm
	./qcontrol.sh createq 1..15
	./build.sh initdb
	./build.sh db
	./loadTest.sh run 1..15
	./loadTest.sh report 1..15
	./qcontrol.sh delqm
	./build.sh dropdb



1. Current Limitations/Untested Aspects
==============================================================================
1. MQ and Database operations are not conducted in a distributed transaction.
This means that an MQ dequeue will still succeed if, for example, a database write fails.
The sample programs correctly report this behaviour if it should occur.

2. MQ failover not tested.
Additional exception handling may be required.

3. Database failover to DR not tested. 

4. If queues are not empty at the start of a test, mqproducer and mqconsumer
iterations may not tally correctly. Use (./qcontrol.sh clear x..y) to clear queues. 

5. Currently, Oracle only "officially" support  GCC 3.2.3 with 10g Release 2 (10.2) for IBM zSeries Based Linux
(see Oracle® Database Release Notes http://download-west.oracle.com/docs/cd/B19306_01/relnotes.102/b25399/toc.htm)
In practice, I have been able to get this demo to work with GCC 3.4.3 by soft linking the required .so file names



2. Obtain and Install Oracle Database 10g
==============================================================================
This sample requires an Oracle Database server. Only 10g has been tested, but there
is nothing in the sample that shouldn't work with other versions of the server.

If you do not already have an Oracle Database server available, see Oracle OTN
to obtain free developer versions:
http://www.oracle.com/technology/software/products/database/oracle10g/index.html

Follow the Oracle installation instructions to setup and test the database server.



3. Obtain and Install Websphere MQ
==============================================================================
This sample requires a Websphere MQ server. Only Websphere MQ 6.0 for Linux has been tested.

A trial version of Websphere MQ is available for download from IBM (http://www.ibm.com) 

See Websphere documentation and information available at
http://www-306.ibm.com/software/integration/wmq/library/?S_CMP=rnav



4. Setting up mqm user for ORACLE environment
==============================================================================

Recommended approach is to install Oracle Instant Client for the mqm user.
This means mqm user does not need any special oracle installation privileges.

A script (installInstantClient.sh) has been provided to install and config the Instant Client.
Installation procedure is as follows:

1. Change to the directory where the instant client directory should be held. mqm home is fine:
[mqm@tintin occimqdemo]$ cd

2. Copy the 3 Instant Client zip files into this directory
[mqm@tintin mqm]$ cp /downloads/instantclient-basic-linux32-10.2.0.3-20061115.zip .
[mqm@tintin mqm]$ cp /downloads/instantclient-sdk-linux32-10.2.0.3-20061115.zip .
[mqm@tintin mqm]$ cp /downloads/instantclient-sqlplus-linux32-10.2.0.3-20061115.zip .

3. Run the installInstantClient.sh script
[mqm@tintin mqm]$ occimqdemo/installInstantClient.sh

this will unpack and fixup the installation ... read the output

4. Fixup the .bash_profile file as instructed.
e.g. you will be told to add the following lines:
export ORACLE_HOME=/var/mqm/instantclient_10_2
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=$PATH:$ORACLE_HOME/bin
export ORACLE_SID=OCCIMQDEMO

5. Configure tnsnames.ora for your database 
see next section (Setting up ORACLE tnsnames.ora)

6. Re-login to mqm user, should be ready to go



5. Setting up ORACLE tnsnames.ora
==============================================================================

"OCCIMQDEMO" is the standard database connection name used in the scripts. Set this up
appropriately in the $ORACLE_HOME/network/admin/tnsnames.ora file.

For example, a single-instance database connection:
OCCIMQDEMO =
	(DESCRIPTION=
		(ADDRESS=(PROTOCOL=TCP)(HOST=tintin.urion.com)(PORT=1521))
		(CONNECT_DATA=
			(SERVER=DEDICATED)
			(SERVICE_NAME=ORCL.tintin.urion.com)
		)
	)

For example, a RAC connection:
OCCIMQDEMO =
	(DESCRIPTION=
		(ADDRESS_LIST =
			(ADDRESS=(PROTOCOL=TCP)(HOST=tintin-rac1vip.urion.com)(PORT=1521))
			(ADDRESS=(PROTOCOL=TCP)(HOST=tintin-rac2vip.urion.com)(PORT=1521))
			(FAILOVER=yes)
			(LOAD_BALANCE=yes)
		)
		(CONNECT_DATA=
			(SERVER=DEDICATED)
			(SERVICE_NAME=MYRAC.tintin.urion.com)
			(FAILOVER_MODE=(TYPE=SELECT)(METHOD=BASIC)(RETRIES=1)(DELAY=5))
		)
	)




6. Setting up MQ OCCIMQDEMO environment
==============================================================================
MQ Environment setup tasks are built into the qcontol.sh script. The two 
required setup steps are to create a queue manager (initqm), and create
some queues (createq)

[mqm@tintin occimqdemo]$ ./qcontrol.sh

  OCCI/MQ Demo MQ Control Script

  Usage:
    ./qcontrol.sh help            ... this message
    ./qcontrol.sh initqm          ... create and start the queue manager
    ./qcontrol.sh startqm         ... start the queue manager
    ./qcontrol.sh stopqm          ... stop the queue manager
    ./qcontrol.sh delqm           ... stop and delete the queue manager
    ./qcontrol.sh createq qRange  ... create queue/queue range
    ./qcontrol.sh qstatus qRange  ... show status of queue/queue range
    ./qcontrol.sh clearq qRange   ... clear queue/queue range
    ./qcontrol.sh deleteq qRange  ... delete queue/queue range

  Where
    qRange = queue number or range {a | a..b}
             (queue number "a", or queues from "a" to "b")


Setup example:
1. create and start the OCCIMQ.QMgr queue manager
[mqm@tintin occimqdemo]$ ./qcontrol.sh initqm

2. create 100 queues:
[mqm@tintin occimqdemo]$ ./qcontrol.sh createq 1..100




7. Build the OCCIMQDEMO sample programs
==============================================================================
Building the sample program (C++ and database schema) is controlled with
the build.sh script. 


[mqm@tintin occimqdemo]$ ./build.sh

  Demo build script for OCCI/MQ Demo dbLibrary.

  Usage - OCCIMQDEMO Schema Database operations:
    ./build.sh initdb         ... initialise the demo database (create the
                          occimqdemo user and sample tables)
    ./build.sh testdb         ... simple PL/SQL test of the occimqdemo user
                          and sample tables
    ./build.sh cleandb        ... cleanout all the occimqdemo tables
    ./build.sh dropdb         ... to drop all occimqdemo objects
    ./build.sh dbstatus       ... show db status

  Usage - C++ sample code operations. Generates:

    ./build.sh stub [verbose] ... build the stub sources, optionally with verbose
                          output on if specified
    ./build.sh db [verbose]   ... build the db-integrated sources, optionally with
                          verbose output on if specified
    ./build.sh demodb         ... build the dbLibrary demo using Oracle demo_rdbms.mk
                         (Use this to get platform-specific library info
                          that may need to be updated in occimq.mk)
    ./build.sh clean          ... clean up compiled files



7a. Initialising ORACLE OCCIMQDEMO schema for the demo
------------------------------------------------------------------------------
Schema management is built into the build.sh script.

Example usage:

1. create the occimqdemo user and sample tables (will prompt for system password):
[mqm@tintin occimqdemo]$ ./build.sh initdb

2. cleanup the schema after test runs (resets the schema - will delete all information)
[mqm@tintin occimqdemo]$ ./build.sh cleandb

3. completely drop the schema:
[mqm@tintin occimqdemo]$ ./build.sh dropdb



7b. Build the C++ sample programs
------------------------------------------------------------------------------
C++ sample programs include:
    bin/mqproducer     (executable test program)
    bin/mqconsumer     (executable test program)
    bin/dblibrary_test (executable db test program)

Examples for building the C++ test program:

1. Standard build - with database support, verbose output disabled:
[mqm@tintin occimqdemo]$ ./build.sh db

2. Standard build - with database support, verbose output enabled:
[mqm@tintin occimqdemo]$ ./build.sh db verbose

3. Stubbed build - programs without "dummy" db support (no Oracle environment required)
[mqm@tintin occimqdemo]$ ./build.sh stub verbose



7c. Verifying Correct Build Libraries for OCCI
------------------------------------------------------------------------------
The makefile (occimq.mk) is configured to build with OCCI libraries
appropriate for Oracle 10gR2 on Linux x86.

To build on other environments, the libraries and includes may need to be
adjusted. Specifically, the CFLAGS, ORACFLAGS, LFLAGS and ORALFLAGS variables
in occimq.mk may need to be revised.

The easiest way to do this is to build the dblibrary_test program with the
makefile distributed with oracle, examine the libraries used, and update
occimq.mk accordingly.

The build.sh script has an operation to do such a build:

	./build.sh demodb

This will work provided the platform you are using contains the
$ORACLE_HOME/rdbms/demo/demo_rdbms.mk file. If not, consult the database
documentation for the platform concerned.



8. Running the demo
==============================================================================
Program execution is built into the loadtest.sh script:

[mqm@tintin occimqdemo]$ ./loadTest.sh

  OCCI/MQ Demo Test Runner Script

  Usage:
    ./loadTest.sh help            ... this message
    ./loadTest.sh run qRange pTimeout pThinktime cTimeout
                       ... runs test pairs (producer/consumer) for specified queues
    ./loadTest.sh prod qRange pTimeout pThinktime
                       ... only starts a producer for specified queues
    ./loadTest.sh cons qRange cTimeout
                       ... only starts a consumer for specified queues
    ./loadTest.sh tail qRange     ... tails log files for test programs for specified queues
    ./loadTest.sh report qRange   ... generates report from logfiles for specified queues


  Where
    qRange    = queue number or range {a | a..b}
               (queue number "a", or queues from "a" to "b")
    pTimeout   = producer timeout in seconds (default=120)
    pThinktime = producer message injection delay (default=0)
    cTimeout   = consumer timeout in seconds (default=30)



NB: running the "load" operation will implicitly call "tail" after the programs have all been started.

Example usage:

1. Run a test with 1 producer-consumer pair for 20 seconds:
[mqm@tintin occimqdemo]$ ./loadTest.sh run 1 20

2. Run a test with 15 producer-consumer pairs for 120 seconds:
[mqm@tintin occimqdemo]$ ./loadTest.sh run 1..15 120

3. Watch the logs in real-time during a load test for queues 5 to 10:
NB: running the "run" operation will implicitly call "tail" after the programs have all been started.
[mqm@tintin occimqdemo]$ ./loadTest.sh tail 5..10

4. Generate a report from a run for queues 1 to 10
[mqm@tintin occimqdemo]$ ./loadTest.sh report 1..10



9. Generate a Test Report
==============================================================================
Report generation is built into the loadtest.sh script:

1. Generate a report from a run for queues 1 to 10
[mqm@tintin occimqdemo]$ ./loadTest.sh report 1..10

This will procude a report which could be redirected to a text file and analysed with Excel.
Example output (admittedly on a slow machine):

Instance, Producer Iterations, Producer Msg Sent OK, Producer Msg Reply OK, Consumer Iterations, Consumer Msg In OK, Consumer Msg Saved to DB OK, Consumer Msg Out OK, Test Duration(secs), Producer Iterations per second, Average Response Time, Count Response Time > 1, Slowest Response Time > 1, Producer Errors, Consumer Errors, TAF Failovers
1, 43235, 43235, 43235, 43235, 43235, 43235, 43235, 600, 72, 0.0103713, 18, 3.09328, 0, 0, 0
2, 42872, 42872, 42872, 42872, 42872, 42872, 42872, 600, 71, 0.0106544, 18, 3.09214, 0, 0, 0
3, 42867, 42867, 42867, 42867, 42867, 42867, 42867, 600, 71, 0.0106341, 18, 3.09163, 0, 0, 0
4, 43126, 43126, 43126, 43126, 43126, 43126, 43126, 600, 71, 0.0104773, 18, 3.09137, 0, 0, 0
5, 42970, 42970, 42970, 42970, 42970, 42970, 42970, 600, 71, 0.0105106, 18, 3.09185, 0, 0, 0
6, 42915, 42915, 42915, 42915, 42915, 42915, 42915, 600, 71, 0.0105912, 18, 3.09264, 0, 0, 0
7, 43167, 43167, 43167, 43167, 43167, 43167, 43167, 600, 71, 0.0105066, 18, 3.092, 0, 0, 0
8, 43249, 43249, 43249, 43249, 43249, 43249, 43249, 600, 72, 0.010494, 18, 3.09296, 0, 0, 0
9, 43028, 43028, 43028, 43028, 43028, 43028, 43028, 600, 71, 0.010564, 18, 3.09189, 0, 0, 0
10, 43218, 43218, 43218, 43218, 43218, 43218, 43218, 600, 72, 0.0104776, 18, 3.093, 0, 0, 0



Notes on the above report:
1) producer and consumer itermations and successful msg send/receieve all tally, which is what we want (no dropped messages)
2) 15 messages fell outside the 1sec threashold for a reply, which is a concern. This was a slow/overloaded machine so perhaps expected.
3) to compare results without the database access, you could re-run the test after building with the dbstub:
	./build.sh stub
	./loadTest.sh run 1..10 600
	./loadTest.sh report 1..10

For example, this now reports:
Instance, Producer Iterations, Producer Msg Sent OK, Producer Msg Reply OK, Consumer Iterations, Consumer Msg In OK, Consumer Msg Saved to DB OK, Consumer Msg Out OK, Test Duration(secs), Producer Iterations per second, Average Response Time, Count Response Time > 1, Slowest Response Time > 1, Producer Errors, Consumer Errors, TAF Failovers
1, 57529, 57529, 57529, 57529, 57529, 57529, 57529, 600, 95, 0.00220925, 1, 1.28549, 0, 0, 0
2, 57366, 57366, 57366, 57366, 57366, 57366, 57366, 600, 95, 0.00211662, 1, 1.31558, 0, 0, 0
3, 57590, 57590, 57590, 57590, 57590, 57590, 57590, 600, 95, 0.00213661, 1, 1.28589, 0, 0, 0
4, 57771, 57771, 57771, 57771, 57771, 57771, 57771, 600, 96, 0.00212538, 1, 1.30506, 0, 0, 0
5, 57591, 57591, 57591, 57591, 57591, 57591, 57591, 600, 95, 0.00216829, 1, 1.30558, 0, 0, 0
6, 57655, 57655, 57655, 57655, 57655, 57655, 57655, 600, 96, 0.00208699, 1, 1.30506, 0, 0, 0
7, 57675, 57675, 57675, 57675, 57675, 57675, 57675, 600, 96, 0.00212047, 1, 1.305, 0, 0, 0
8, 57704, 57704, 57704, 57704, 57704, 57704, 57704, 600, 96, 0.00205405, 1, 1.3043, 0, 0, 0
9, 57578, 57578, 57578, 57578, 57578, 57578, 57578, 600, 95, 0.00217947, 1, 1.30432, 0, 0, 0
10, 57705, 57705, 57705, 57705, 57705, 57705, 57705, 600, 96, 0.00197397, 1, 1.29046, 0, 0, 0


10. Checking Queue Status
==============================================================================
Queue control is built into the qcontol.sh script (see "Setup MQ Environment" above).

Sample usage:

1. Show the status of queues 5 to 10:
[mqm@tintin occimqdemo]$ ./qcontrol.sh qstatus 5..10

2. Clear queues 1 to 10:
[mqm@tintin occimqdemo]$ ./qcontrol.sh clearq 1..10









