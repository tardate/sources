--
-- demonstrates collapsing an XML structure down to a vector of paths and values
-- see discussion at http://forums.oracle.com/forums/thread.jspa?messageID=1696372
-- uses xsl approach with path tracing (see http://www.dpawson.co.uk/xsl/sect2/N6077.html for more info)
--
-- $Id: extractPaths.sql,v 1.2 2007/02/17 18:08:52 paulg Exp $
-- author: Paul Gallagher gallagher.paul@gmail.com
--

set serveroutput on
set LINESIZE 132

DROP TABLE x1;
CREATE TABLE x1 (item varchar(25) primary key, xml xmltype);

INSERT INTO x1 VALUES ('data',
'<?xml version="1.0" encoding="ISO-8859-1"?>
<FamilyHistory>
 <Family>
  <Sponsor>
   <Name>
    <Last>Jones</Last>
    <First>Tom</First>
   </Name>
   <SSN>123456781</SSN>
  </Sponsor>
    <Children>
      <Child>
        <Name>
          <Last>Smith</Last>
          <First>Sandra</First>
        </Name>
        <SSN>123456783</SSN>
        <Allergies>
          <Allergy>
            <Allergen>Dust</Allergen>
            <TreatmentType>Injection</TreatmentType>
            <Treatments>
              <Treatment>
                <Date>20040118</Date>
                <Reaction>None</Reaction>
              </Treatment>
              <Treatment>
                <Date>20040220</Date>
                <Reaction>Redness</Reaction>
              </Treatment>
            </Treatments>
          </Allergy>
          <Allergy>
            <Allergen>Ragweed</Allergen>
            <Treatment>None</Treatment>
          </Allergy>
        </Allergies>
      </Child>
      <Child>
        <Name>
          <Last>Jones</Last>
          <First>Carolyn</First>
        </Name>
        <SSN>123456782</SSN>
      </Child>
    </Children>
  </Family>
</FamilyHistory>');

INSERT INTO x1 VALUES ('xsl-to-xml',
'<?xml version="1.0" encoding="windows-1252" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml"/>
<xsl:strip-space elements = "*" />
<xsl:template match="/">
  <items>
    <xsl:apply-templates/>
  </items>
</xsl:template>
<xsl:template match="text()">
  <item>
    <path>
      <xsl:for-each select="ancestor-or-self::*">
        <xsl:text>/</xsl:text>
        <xsl:value-of select="name()" />
      </xsl:for-each>
    </path>
    <value>
      <xsl:value-of select="." />
      <xsl:apply-templates/>
    </value>
  </item>
</xsl:template>
</xsl:stylesheet>');

INSERT INTO x1 VALUES ('xsl-to-text',
'<?xml version="1.0" encoding="windows-1252" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>
<xsl:strip-space elements = "*" />
<xsl:template match="text()">
  <xsl:for-each select="ancestor-or-self::*">
    <xsl:text>/</xsl:text>
    <xsl:value-of select="name()" />
  </xsl:for-each>
  <xsl:text>():</xsl:text>
  <xsl:value-of select="." />
  <xsl:text>, &#xA;</xsl:text>
  <xsl:apply-templates/>
</xsl:template>
</xsl:stylesheet>');

declare
v_out_xml xmltype;
v_out_text varchar(4000);
begin

dbms_output.put_line('-- as text list:');
select 
  XMLTransform(
    xml, 
    (select xml from x1 where item='xsl-to-text')
  ).getstringval() into v_out_text
from x1 where item='data'; 
dbms_output.put_line(v_out_text);

dbms_output.put_line('-- as xml structure:');
select 
  XMLTransform(
    xml, 
    (select xml from x1 where item='xsl-to-xml')
  ) into v_out_xml
from x1 where item='data'; 
dbms_output.put_line(v_out_xml.getstringval());


end;

/