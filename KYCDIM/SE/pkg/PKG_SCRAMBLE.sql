CREATE OR REPLACE PACKAGE pkg_scramble
AS
TYPE t_keys
IS
  TABLE OF VARCHAR2(50) INDEX BY VARCHAR2(50);
  v_keys t_keys;
  ---------------------------------------
  PROCEDURE scramble;
  --------------------------------------
  FUNCTION get_value(
      p_json clob,
      p_obj        VARCHAR2,
      p_appearance NUMBER DEFAULT 1)
    RETURN VARCHAR2;
  --------------------------------------
  PROCEDURE scr_obj(
      l_json IN OUT clob ,
      p_obj   VARCHAR2,
      p_value VARCHAR2 default null);
END pkg_scramble;
/


CREATE OR REPLACE PACKAGE body pkg_scramble
AS
  ------------------------------------------------------
  PROCEDURE scramble
  AS
    l_obj_len NUMBER;
    l_obj     VARCHAR2(50);
    json_rec A10OOCST%rowtype;
    CURSOR hhoose_cur
    IS
      SELECT json FROM A10OOCST;
      
  BEGIN
    v_keys ('personalNumber')          := 'NUMBER(10)';
    v_keys ('customer.address.mobile') := 'NUMBER(9)';
    l_obj                              := 'personalNumber';
    FOR json_rec IN
    ( SELECT * FROM A10OOCST
    )
    LOOP
      --DBMS_OUTPUT.put_line (pkg_scramble.get_value(json_rec.json, l_obj));
      NULL;
    END LOOP;
    /*SELECT LENGTH(SUBSTR(json, instr(json, ':', instr(json,l_obj))+2, instr(json, '"', instr(json,l_obj), 3)-instr(json, '"', instr(json,l_obj),2)-1 ))
    INTO l_obj_len
    FROM hhoose_json;*/
  END scramble;
------------------------------------------------------
  FUNCTION get_value(
      p_json CLOB,
      p_obj        VARCHAR2,
      p_appearance NUMBER DEFAULT 1)
    RETURN VARCHAR2
  IS
    l_ret VARCHAR2(4096);
  BEGIN
    --l_ret := SUBSTR(p_json, instr(p_json, ':', instr(p_json,p_obj))+3, instr(p_json, '"', instr(p_json,p_obj), 3)-instr(p_json, '"', instr(p_json,p_obj),2)-1 );
    l_ret := SUBSTR(p_json, instr(p_json, ':', instr(p_json,p_obj,1,p_appearance))+2, instr(p_json, '"', instr(p_json,p_obj,1,p_appearance), 3)-instr(p_json, '"', instr(p_json,p_obj,1,p_appearance),2)-1 );
    RETURN l_ret;
  END get_value;
------------------------------------------------------
  PROCEDURE scr_obj(
      l_json IN OUT CLOB ,
      p_obj   VARCHAR2,
      p_value VARCHAR2 DEFAULT NULL)
  IS
    l_amount NUMBER;
  BEGIN
    l_amount := REGEXP_COUNT(l_json, p_obj);
    FOR i IN 1..l_amount
    LOOP
      IF LENGTH(get_value(l_json, p_obj, i)) > 0 THEN
        l_json                              := REPLACE(l_json, '"'||p_obj||'":"'||get_value(l_json, p_obj, i)||'"', '"'||p_obj||'":"'||dbms_obfuscation_toolkit.md5(input => UTL_RAW.cast_to_raw(get_value(l_json, p_obj, i)))||'"');
      END IF;
    END LOOP;
  END scr_obj;
END pkg_scramble;
/
