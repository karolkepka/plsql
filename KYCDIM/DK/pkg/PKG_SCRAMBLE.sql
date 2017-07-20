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
      p_json CLOB,
      p_obj        VARCHAR2,
      p_appearance NUMBER DEFAULT 1)
    RETURN VARCHAR2;
  --------------------------------------
  PROCEDURE scr_obj(
      l_json IN OUT A10OOCDT.json%type ,
      p_obj   VARCHAR2,
      p_value VARCHAR2 DEFAULT NULL);
  --------------------------------------
  FUNCTION scr_val(
      p_value VARCHAR2)
    RETURN VARCHAR2;
  --------------------------------------
  PROCEDURE deplo;
END pkg_scramble;
/


CREATE OR REPLACE PACKAGE body pkg_scramble
AS
  ------------------------------------------------------
  PROCEDURE scramble -- DRAFT
  AS
    l_obj_len NUMBER;
    l_obj     VARCHAR2(50);
    json_rec A10OOCDT%rowtype;
    CURSOR hhoose_cur
    IS
      SELECT json FROM A10OOCDT;
  BEGIN
    v_keys ('personalNumber')          := 'NUMBER(10)';
    v_keys ('customer.address.mobile') := 'NUMBER(9)';
    l_obj                              := 'personalNumber';
    FOR json_rec IN
    ( SELECT * FROM A10OOCDT
    )
    LOOP
      NULL;
    END LOOP;
  END scramble;
------------------------------------------------------
  FUNCTION get_value(
      p_json CLOB,
      p_obj        VARCHAR2,
      p_appearance NUMBER DEFAULT 1)
    RETURN VARCHAR2
  IS
    l_ret        VARCHAR2(4096);
    l_obj        VARCHAR2(100);
    l_obj_loc    NUMBER;
    l_subobj     VARCHAR2(100);
    l_subobj_loc NUMBER;
  BEGIN
    IF instr(p_obj, '+') <> 0 THEN
      l_obj              := SUBSTR(p_obj, 1, instr(p_obj, '+')-1);
      l_subobj           := SUBSTR(p_obj, instr(p_obj, '+')   +1);
    ELSE
      l_obj := p_obj;
    END IF;
    IF l_subobj      IS NOT NULL THEN
      l_obj_loc      := instr(p_json, l_obj, 1, p_appearance);
      IF l_obj_loc   <> 0 THEN
        l_subobj_loc := instr(p_json, l_subobj, l_obj_loc, 1)+ LENGTH(l_subobj);
        l_ret        := regexp_substr(p_json, '("(\d*\w*)"){1}', l_subobj_loc,1,'i',2);
      ELSE
        l_ret := NULL;
      END IF;
    ELSE
      l_ret := SUBSTR(p_json, instr(p_json, ':', instr(p_json,p_obj,1,p_appearance))+2, instr(p_json, '"', instr(p_json,p_obj,1,p_appearance), 3)-instr(p_json, '"', instr(p_json,p_obj,1,p_appearance),2)-1 );
    END IF;
    RETURN l_ret;
  END get_value;
------------------------------------------------------
  PROCEDURE scr_obj(
      l_json IN OUT A10OOCDT.json%type ,
      p_obj   VARCHAR2,
      p_value VARCHAR2 DEFAULT NULL)
  IS
    l_amount       NUMBER(38);
    l_obj          VARCHAR2(100);
    l_obj_loc      NUMBER;
    l_subobj       VARCHAR2(100);
    l_subobj_loc   NUMBER;
    l_obj_val      VARCHAR2(300);
    l_obj_val_prev VARCHAR2(300);
  BEGIN
    IF instr(p_obj, '+') <> 0 THEN
      l_obj              := SUBSTR(p_obj, 1, instr(p_obj, '+')-1);
      l_subobj           := SUBSTR(p_obj, instr(p_obj, '+')   +1);
    ELSE
      l_obj := p_obj;
    END IF;
    l_amount := REGEXP_COUNT(l_json, l_obj);
    --dbms_output.put_line(l_amount);
    FOR i IN 1..l_amount
    LOOP
      IF l_subobj               IS NOT NULL THEN
        l_obj_loc               := instr(l_json, l_obj, 1, i);
        IF l_obj_loc            <> 0 THEN
          l_subobj_loc          := instr(l_json, l_subobj, l_obj_loc, 1)+ LENGTH(l_subobj);
          l_obj_val             := get_value(l_json, p_obj, i);
          IF scr_val(l_obj_val) <> NVL(l_obj_val_prev,0) THEN
            l_json              := regexp_replace(l_json, '("(\d*\w*)"){1}', '"'||scr_val(l_obj_val)||'"', l_subobj_loc,1);
            l_obj_val_prev      := scr_val(l_obj_val);
          END IF;
        END IF;
      ELSE
        l_obj_val             := get_value(l_json, p_obj, i);
        IF scr_val(l_obj_val) <> NVL(l_obj_val_prev,0) THEN
          l_json              := REPLACE(l_json, '"'||l_obj||'":"'||l_obj_val||'"', '"'||l_obj||'":"'||scr_val(l_obj_val)||'"');
          l_obj_val_prev      := scr_val(l_obj_val);
        END IF;
      END IF;
    END LOOP;
  END scr_obj;
------------------------------------------------------
  FUNCTION scr_val(
      p_value VARCHAR2)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN dbms_obfuscation_toolkit.md5(input => UTL_RAW.cast_to_raw(NVL(p_value, '0')));
  END scr_val;
----------------
  PROCEDURE deplo
  IS
    CURSOR json_cur
    IS
      SELECT json
      FROM A10OOCDT  --where person_no = 1712782133 --rownum < 100 order by id desc*/
        FOR UPDATE;
    /* OF A10OOCDT.json_scr;*/
    json_rec json_cur%rowtype;
    l_json A10OOCDT.json%type;
    l_pn      VARCHAR2(20);
    l_pn_n    VARCHAR2(20);
    l_pn_cnt  VARCHAR2(20) := '001';
    l_email   VARCHAR2(100);
    l_email_n VARCHAR2(100);
  BEGIN
    FOR json_rec IN json_cur
    LOOP
      l_json := json_rec.json;
      pkg_scramble.scr_obj(l_json, 'TAX.DOMECILE.TIN.1+text');
      l_pn   := pkg_scramble.get_value(l_json, 'personNo');
      l_pn_n := SUBSTR(l_pn, 1,6) || l_pn_cnt;
      --pkg_scramble.scr_obj(l_json, 'personNo');
      pkg_scramble.scr_obj(l_json, 'firstName');
      pkg_scramble.scr_obj(l_json, 'lastName');
      pkg_scramble.scr_obj(l_json, 'fullName');
      pkg_scramble.scr_obj(l_json, 'addressLine');
      --pkg_scramble.scr_obj(l_json, 'email');
      pkg_scramble.scr_obj(l_json, 'mobile');
      pkg_scramble.scr_obj(l_json, 'streetName');
      pkg_scramble.scr_obj(l_json, 'customerNo');
      pkg_scramble.scr_obj(l_json, 'sortGroup');
      pkg_scramble.scr_obj(l_json, 'idcard');
      pkg_scramble.scr_obj(l_json, 'idNumber');
      pkg_scramble.scr_obj(l_json, 'cardNo');
      l_email               := get_value(l_json, 'email');
      IF instr(l_email, '@') > 0 THEN
        l_email_n           := scr_val(SUBSTR(l_email, 1, instr(l_email, '@')-1))||SUBSTR(l_email, instr(l_email, '@'));
        l_json              := REPLACE(l_json, l_email, l_email_n);
      END IF;
      l_json := REPLACE(l_json, l_pn, l_pn_n);
      --      dbms_output.put_line(l_json);
      UPDATE A10OOCDT
      SET json_scr    = l_json,
        PERSON_NO_SCR = l_pn_n --pkg_scramble.scr_val(PERSON_NO)
      WHERE CURRENT OF json_cur;
      IF l_pn_cnt = '999' THEN
        l_pn_cnt := '001';
      END IF;
      l_pn_cnt := lpad( l_pn_cnt + 1, 4, 0 );
    END LOOP;
    COMMIT;
  END deplo;
END pkg_scramble;
/
