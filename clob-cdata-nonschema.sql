--
-- demonstrates generating an XML structure with large >32k? CLOB string elements
-- see discussion at http://forums.oracle.com/forums/thread.jspa?threadID=476322
--
-- $Id: clob-cdata-nonschema.sql,v 1.1 2007/02/19 08:40:01 paulg Exp $
-- author: Paul Gallagher gallagher.paul@gmail.com
--

CREATE TABLE x1 (item varchar(25) primary key, bigdata clob);

CREATE OR REPLACE TYPE x1_t AS OBJECT 
(Holder varchar(25),BookData CLOB);
/

CREATE OR REPLACE VIEW vx1 OF XMLTYPE
WITH OBJECT ID (ExtractValue(sys_nc_rowinfo$, '/ROW/HOLDER')) AS
SELECT sys_XMLGen(x1_t(x.item, x.bigdata)) from x1 x;



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


SELECT
	extractvalue(x.SYS_NC_ROWINFO$,'/ROW/HOLDER') as holder
	,'xml_length: ' || dbms_lob.getlength(x.SYS_NC_ROWINFO$.getclobval()) as xml_length
FROM vx1 x;

set long 2000
set pages 100
PROMPT "selecting from xmltype view:"
select * from vx1;


-- cleanup
DROP VIEW vx1;
DROP TYPE x1_t;
DROP TABLE x1;
