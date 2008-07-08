#!/bin/bash
#-----------------------------------------------------------------------
# Purpose:  verification of directory-integrated Oracle SSO configuration.
#           See: http://tardate.blogspot.com/2007/05/validating-oracle-sso-configuration.html
#           for a discussion of this script.
#
#           This script performs a series of tests, which at the time of writting are
#           thought to be a good indication that your SSO server credentials are
#           properly setup. This script makes no changes in the ORASSO schema or OID.
#           No warranty is made that this script will give a correct certification
#           that Oracle SSO and OID are properly configured. 
#
#           The script performs the following tests:
#
#           1. Retrieve the ORASSO schema password from orclResourceName=ORASSO in ldap
#           2. Verifying that the SSO_SERVER details from ORASSO schema are valid
#           3. Verifying that the SSO_SERVER specified in ORASSO can bind to OID
#           4. Verifying that the SSO_SERVER has the necessary OID group memberships
#
#           For more information, see:
#             Note:315534.1 How to Verify that SSO can Communicate with OID
#             Note:191352.1 How Do I Find the Randomized Password Assigned to ORASSO?
#             Note:199633.1 Unix Script to Determine orasso Password
#             Bug: 4992712  For information on group memberships
#
#           The script is configured using a .conf file of the same name as this script. 
#           If the .conf does not exist, the script will generate a
#           default template on first execution.
#
#           The script assumes an appropriate ORACLE environment is set when script
#           is invoked (but you can set it in the .conf file if you wish).
#
# Author:   Paul Gallagher
# $Id: validateSso.sh,v 1.14 2007/05/20 02:58:41 paulg Exp $
#-----------------------------------------------------------------------

#
# determine script path and name, configuration file name
#
scriptPath=${0%/*}/
scriptName=${0#$scriptPath*}
confFile=${0%.*}.conf
tmpFile=${0%.*}.tmp


#
# set/load configuration settings
#
if [ ! -e $confFile ]
then
 # generate a default configuration file
cat > $confFile <<END_DEFAULT_CONF
#-----------------------------------------------------------------------
# CONFIGURATION SETTINGS
# NB: to modify, edit $confFile. Do not edit these in $scriptName

# TNS name of the database containing the ORASSO schema to check
my_sid=ORCL

# LDAP/OID host and port used by the SSO service
my_ldaphost=localhost
my_ldapport=389
my_adminuid=cn=orcladmin

# END CONFIGURATION SETTINGS
#-----------------------------------------------------------------------
END_DEFAULT_CONF
echo "***************************************************************"
echo "A default configuration file has been generated in $confFile"
echo "Please review/customise this file and then re-run $scriptName"
exit 0
fi
# load configuration
. $confFile


#
# banner
#
echo "***************************************************************"
echo "Oracle directory-integrated SSO configuration verification"
echo ""

#
# get the directory password if not already set (in conf file)
#
if [ "$my_adminpwd" = "" ]
  then
  echo -n "Enter the directory admin ($my_adminuid) password: " >&2
  read -s my_adminpwd
  echo ""
fi


#
#
echo ""
echo "STEP 1"
echo "Retrieve the ORASSO schema password from orclResourceName=ORASSO in ldap://${my_ldaphost}:${my_ldapport}"

orclpasswordattribute=$(ldapsearch -D $my_adminuid -w $my_adminpwd -p $my_ldapport -h $my_ldaphost -b "cn=IAS, cn=Products, cn=OracleContext" -s sub orclResourceName=ORASSO orclpasswordattribute |tail -n 1 | awk 'BEGIN { FS="=" } ; { print $2 }')
rc=$?

if [ $orclpasswordattribute ]
then
  echo "... ORASSO schema password retrieved [$orclpasswordattribute]"
else
  echo "*** Failed to retrieve the ORASSO schema password. [rc=$rc]"
  echo "Can't go much further - need to know the ORASSO schema password and this needs to be set in OID."
  echo "To find out how to do this, see: XXXXXX [TODO]"
fi


#
#
echo ""
echo "STEP 2"
echo "Retrieve SSO configuration from ORASSO schema"

sqlplus /nolog > $tmpFile 2> /dev/null <<CHECK_LDAP_CONFIG
conn orasso/${orclpasswordattribute}@${my_sid}
set serveroutput on
exec wwsso_oid_integration.show_ldap_config;
exit
CHECK_LDAP_CONFIG

#returns:
# OID HOST: oid-ais.aozora.lan
#SSO_OID_HOST=
# OID PORT: 10238
#SSO_OID_PORT=
# SSO SERVER DN:
#SSO_DN=orclApplicationCommonName=ORASSO_SSOSERVER,cn=SSO,cn=Products,cn=OracleContext
# OID USE SSL: Y
#SSO_SERVER_PASSWORD=FAFF00152CEB87BA21A4EF3A7BCD495A
SSO_SSL=$(grep "OID USE SSL" $tmpFile | awk 'BEGIN { FS=":" } ; { print $2 }' | sed "s/^\s*//g")
echo "SSO_SSL=$SSO_SSL"
SSO_OID_HOST=$(grep "OID HOST" $tmpFile | awk 'BEGIN { FS=":" } ; { print $2 }' | sed "s/^\s*//g")
echo "SSO_OID_HOST=$SSO_OID_HOST"
SSO_OID_PORT=$(grep "OID PORT" $tmpFile | awk 'BEGIN { FS=":" } ; { print $2 }' | sed "s/^\s*//g")
echo "SSO_OID_PORT=$SSO_OID_PORT"
SSO_DN=$(grep "cn=OracleContext" $tmpFile | sed "s/^\s*//g")
echo "SSO_DN=$SSO_DN"
SSO_SERVER_PASSWORD=$(grep "SSO SERVER PASSWORD" $tmpFile | awk 'BEGIN { FS=":" } ; { print $2 }' | sed "s/^\s*//g")
echo "SSO_SERVER_PASSWORD=$SSO_SERVER_PASSWORD"


#
#
echo ""
echo "STEP 3"
echo "Verifying that the SSO_SERVER details from ORASSO schema are valid"

if [ "$SSO_OID_HOST" = "$my_ldaphost" ]
then
  echo "... OID host registered for SSO matches the one you told me to use [$my_ldaphost]"
else
  echo "*** OID host registered for SSO [$SSO_OID_HOST] is"
  echo "    NOT the same as the one you told me to use [$my_ldaphost]"
fi

if [ "$SSO_OID_PORT" = "$my_ldapport" ]
then
  echo "... OID port registered for SSO matches the one you told me to use [$my_ldapport]"
else
  echo "*** OID port registered for SSO [$SSO_OID_PORT] is"
  echo "    NOT the same as the one you told me to use [$my_ldapport]"
fi


#
#
echo ""
echo "STEP 4"
echo "Verifying that the SSO_SERVER specified in ORASSO can bind to OID"

# now try to bind using the password registered:
ssoServerBind=$(ldapbind -h $my_ldaphost -p $my_ldapport -D "$SSO_DN" -w $SSO_SERVER_PASSWORD)
rc=$?
echo "rc=$rc"
echo "$ssoServerBind"

if [ "$rc" != "0" ]
then
  ssoServerBind="bind failed"
fi

if [ "$ssoServerBind" = "bind successful" ]
then
  echo "... successfully connected to OID using credentials for $SSO_DN"
else
  echo "*** Failed to bind to OID using credentials for $SSO_DN. [rc=$rc]"
  echo "Can't go much further - the SSO_SERVER credentials need to be valid for OID."
  echo "You _may_ need to reset the SSO_SERVER password in OID. e.g.:"
  echo ""
  echo "  ldapmodify -h $my_ldaphost -p $my_ldapport -D $my_adminuid -w $my_adminpwd <<MOD_ORASSO_PWD"
  echo "  dn: $SSO_DN"
  echo "  changetype:modify"
  echo "  replace:userpassword"
  echo "  userpassword:$SSO_SERVER_PASSWORD"
  echo "  MOD_ORASSO_PWD"
  echo ""
  exit
fi


#
#
echo ""
echo "STEP 5"
echo "Verifying that the SSO_SERVER has the necessary OID group memberships"

# first, get unique list entries as recorded in the uniquemember attribute of the list
search=$( echo "$SSO_DN" | awk 'BEGIN { FS="," } ; { print $1 }')
search="(&(uniquemember=*${search}*)(objectclass=orclPrivilegeGroup))"
attribs="dn"
base="cn=Groups,cn=OracleContext"

echo "$SSO_DN is a member of the following security groups:"

for v_ownerdn in `ldapsearch -p $my_ldapport -h $my_ldaphost -b $base -D $my_adminuid -w $my_adminpwd -s sub $search $attribs | sed '/^filter\|^returning\|^ldap_open\|^$\|matches$\|^mail=/d'`
do
  echo "... $v_ownerdn"
done

echo ""
echo "DONE"


#
# cleanup
#
rm $tmpFile 2> /dev/null
