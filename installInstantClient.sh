#!/bin/bash

echo "Installation script for Oracle Instant Client"
echo ""
echo "This will install Instant Client Basic + SDK + sqlplus. I need at the following 3 zip"
echo "files in the current directory:"
echo ""
echo "   instantclient-basic*.zip e.g. instantclient-basic-linux32-10.2.0.3-20061115.zip"
echo "   instantclient-sdk*.zip e.g. instantclient-sdk-linux32-10.2.0.2-20060331.zip"
echo "   instantclient-sqlplus*.zip e.g. instantclient-sqlplus-linux32-10.2.0.3-20061115.zip"
echo ""

# check zip file presence. expect to find 3 zips
numfiles=$(ls -ld instantclient*.zip 2> /dev/null | grep -c "^-")

if [ $numfiles != 3 ]
then
  echo "I'm expecting to see 3 Instant Client zip files. What I found is ${numfiles}:"
  ls -ld instantclient*.zip 2> /dev/null
  exit
fi

# unzip into specified directory
echo "Unzipping ..."
unzip instantclient-basic*.zip
unzip instantclient-sdk*.zip
unzip instantclient-sqlplus*.zip

# get the actual directory name
dir=$(ls -ld instantclient* 2> /dev/null | grep "^d" | tail -n 1 | awk '{print $9}')
echo -e "\nIt seems the instant client directory is ${dir}"

# Fixup - bin directory 
echo -e "\nMaking bin directory.."
mkdir ${dir}/bin 2> /dev/null
mv ${dir}/sqlplus ${dir}/bin
mv ${dir}/*.sql ${dir}/bin
mv ${dir}/genezi ${dir}/bin

# Fixup - lib directory
echo -e "\nMaking lib directory.."
mkdir ${dir}/lib 2> /dev/null
mv ${dir}/*.so* ${dir}/lib
mv ${dir}/*.jar ${dir}/lib

# Fixup - .so links
ln ${dir}/lib/libocci.so.10.1 ${dir}/lib/libocci.so
ln ${dir}/lib/libocci.so.10.1 ${dir}/lib/occi.so
ln ${dir}/lib/libclntsh.so.10.1 ${dir}/lib/libclntsh.so
ln ${dir}/lib/libclntsh.so.10.1 ${dir}/lib/clntsh.so

# Fixup - tnsnames.ora
echo -e "\nMaking network/admin directory.."
mkdir ${dir}/network 2> /dev/null
mkdir ${dir}/network/admin 2> /dev/null
if [ ! -e ${dir}/network/admin/tnsnames.ora ]
then
  echo -e "# Dummy tnsnames.ora\n#\n\n" > ${dir}/network/admin/tnsnames.ora
  echo " .. a default tnsnames.ora has been placed in ${dir}/network/admin"
fi
 
# summary results
echo -e "\nInstant Client installed.\n"


echo -e "\nTo set environment, suggest you modify your .bash_profile to add the following (NB: set SID appropriate to your installation):\n"
echo "export ORACLE_HOME=$(pwd)/${dir}"
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib"
echo "export PATH=\$PATH:\$ORACLE_HOME/bin"
echo "export ORACLE_SID=ORCL"
echo ""
echo "Done!"



