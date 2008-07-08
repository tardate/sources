--
-- demonstrates generating an XML structure with large >32k? CLOB string elements
-- see discussion at http://forums.oracle.com/forums/thread.jspa?threadID=476322
--
-- $Id: clob-cdata-schema.sql,v 1.1 2007/02/19 09:26:27 paulg Exp $
-- author: Paul Gallagher gallagher.paul@gmail.com
--

CREATE TABLE x1 (item varchar(25) primary key, bigdata clob);

CREATE OR REPLACE TYPE x1_t AS OBJECT 
(Holder varchar(25),BookData CLOB);
/

exec dbms_xmlschema.registerSchema('http://clob-cdata-schema/x1_t.xsd' ,DBMS_XMLSchema.generateSchema('SCOTT','X1_T'), TRUE, FALSE, FALSE, FALSE);

CREATE OR REPLACE VIEW vx1 OF XMLTYPE
XMLSCHEMA "http://clob-cdata-schema/x1_t.xsd" ELEMENT "X1_T"
WITH OBJECT ID (ExtractValue(sys_nc_rowinfo$, '/ROW/HOLDER')) AS
SELECT x1_t(x.item, x.bigdata) from x1 x;




-- insert some test data

insert into x1 values('test1','<![CDATA[some stuff]]>');
insert into x1 values('test2','Some stuff & <b>with</b> illegal chars');
INSERT INTO x1 VALUES ('mysample',
'<FamilyHistory>
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


-- 
set long 2000
set pages 100

PROMPT "selecting from xmltype view:"
select x.SYS_NC_ROWINFO$.getclobval() from vx1 x;

SELECT
	'xml_length: ' || dbms_lob.getlength(x.SYS_NC_ROWINFO$.getclobval()) as xml_length
FROM vx1 x;



-- cleanup
DROP VIEW vx1;
exec dbms_xmlschema.deleteSchema('http://clob-cdata-schema/x1_t.xsd');
DROP TYPE x1_t;
DROP TABLE x1;
