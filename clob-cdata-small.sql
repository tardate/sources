--
-- demonstrates generating an XML structure with small <32k? CLOB CDATA section
-- see discussion at http://forums.oracle.com/forums/thread.jspa?threadID=476322
-- see also:
--   XMLCdata http://download-west.oracle.com/docs/cd/B19306_01/server.102/b14200/functions216.htm#CIHFBEGB
--
-- $Id: clob-cdata-small.sql,v 1.1 2007/02/19 08:33:50 paulg Exp $
-- author: Paul Gallagher gallagher.paul@gmail.com
--


CREATE TABLE x1 (item varchar(25) primary key, bigdata clob);


-- this is ok with bigdata <=4000 chars

SELECT XMLELEMENT("FamilyHistory",
      XMLATTRIBUTES ( x.item as "ID"),
      XMLCData( x.bigdata)) AS "FamilyHistory Doc"
   FROM x1 x
   WHERE x.item = 'mydata';

CREATE OR REPLACE VIEW vx1 AS
SELECT 
	XMLELEMENT(FAMILYHISTORY,
      XMLATTRIBUTES ( x.item as ID ),
      XMLCData( x.bigdata )
	) AS FamilyHistory
FROM x1 x;


-- insert some test data

INSERT INTO x1 VALUES ('mysample',
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

select
	extract(FamilyHistory,'/FAMILYHISTORY/@ID') as id
	,dbms_lob.getlength(xmltype.getclobval(FamilyHistory)) as xml_length
from vx1;

set long 2000
set pages 100
PROMPT "selecting from xmltype view:"
select * from vx1;

-- cleanup
DROP VIEW vx1;
DROP TABLE x1;
