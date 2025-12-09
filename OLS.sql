CREATE PLUGGABLE DATABASE paperspdb
ADMIN USER papersadm IDENTIFIED BY pwd
ROLES = (DBA)
FILE_NAME_CONVERT = ('pdbseed/', 'pdbpapers/');

ALTER PLUGGABLE DATABASE paperspdb OPEN READ WRITE;
ALTER PLUGGABLE DATABASE paperspdb SAVE STATE;

show USER;
show CON_NAME;

ALTER SESSION SET container = paperspdb;

SELECT default_tablespace, temporary_tablespace
FROM dba_users
WHERE username='PAPERSADM';

SELECT * FROM database_properties
WHERE property_name LIKE '%TABLESPACE';

CREATE TABLESPACE PAPERS_DATA DATAFILE 'papers_data.dbf'
SIZE 100M AUTOEXTEND ON NEXT 10M MAXSIZE 1G;

ALTER USER papersadm DEFAULT TABLESPACE PAPERS_DATA;
ALTER USER papersadm QUOTA 100M ON PAPERS_DATA;

CREATE TABLE papers (
    paper_id       NUMBER PRIMARY KEY,
    paper_title    VARCHAR2(200),
    page_number    NUMBER,
    final_result   VARCHAR2(30),
    paper_status   VARCHAR2(30)
);

INSERT INTO papers VALUES (1, 'Machine Learning Optimization Techniques', 12, 'Pending', 'Submitting');
INSERT INTO papers VALUES (2, 'Deep Neural Network Compression Methods', 10, 'Pending', 'Submitting');
INSERT INTO papers VALUES (3, 'Blockchain-based Access Control System', 8, 'None', 'Locked');
INSERT INTO papers VALUES (4, 'High Performance GPU Computing for AI', 15, 'None', 'Reviewing');
INSERT INTO papers VALUES (5, 'Cybersecurity Threat Detection using AI', 11, 'Rejected', 'Reviewed');
INSERT INTO papers VALUES (6, 'Autonomous Vehicle Path Planning Algorithms', 14, 'Accepted', 'Unready');
INSERT INTO papers VALUES (7, 'Quantum Computing Simulation Framework', 9, 'Accepted', 'Waiting');
INSERT INTO papers VALUES (8, 'Distributed Cloud Storage Optimization', 13, 'Accepted', 'Camera-ready');
INSERT INTO papers VALUES (9, 'Natural Language Processing for Smart Assistants', 7, 'Accepted', 'Editing');
INSERT INTO papers VALUES (10, 'Computer Vision in Medical Image Processing', 16, 'Accepted', 'Checked');


SELECT * FROM papersadm.PAPERS;

---------------------------------------
-- kích hoạt ols
ALTER SESSION SET container = paperspdb;
EXEC LBACSYS.CONFIGURE_OLS;
EXEC LBACSYS.OLS_ENFORCEMENT.ENABLE_OLS;

SELECT * FROM DBA_OLS_STATUS;

---------------------------------------
-- create policy

GRANT connect, create user, drop user, create role, drop any role
TO papers_sec IDENTIFIED BY paperssec;
GRANT connect TO sec_admin IDENTIFIED BY secadmin;

ALTER SESSION SET container = paperspdb;
GRANT INHERIT PRIVILEGES ON USER SYS TO LBACSYS;
alter session set NLS_NUMERIC_CHARACTERS = '.,';

BEGIN
    SA_SYSDBA.CREATE_POLICY (
        policy_name => 'ACCESS_PAPERS',
        column_name => 'OLS_COLUMN');
END;

SELECT *
FROM dba_sa_policies
WHERE policy_name = 'ACCESS_PAPERS';


GRANT access_papers_dba TO sec_admin;
-- Package dùng để tạo ra các thành phần của nhãn
GRANT execute ON sa_components TO sec_admin;
-- Package dùng để tạo các nhãn
GRANT execute ON sa_label_admin TO sec_admin;
-- Package dùng để gán chính sách cho các table/schema
GRANT execute ON sa_policy_admin TO sec_admin;
GRANT execute ON to_lbac_data_label TO sec_admin WITH GRANT OPTION;




GRANT access_papers_dba TO papers_sec;
-- Package dùng để gán các label cho user
GRANT execute ON sa_user_admin TO papers_sec;


Create ROLE user_role;
GRANT connect TO user_role;

CREATE USER auth1 IDENTIFIED BY 123;
GRANT user_role TO auth1;

CREATE USER track_chair IDENTIFIED BY 123;
GRANT user_role TO track_chair;

CREATE USER program_chair IDENTIFIED BY 123;
GRANT user_role TO program_chair;

CREATE USER reviewer1 IDENTIFIED BY 123;
GRANT user_role TO reviewer1;
CREATE USER reviewer2 IDENTIFIED BY 123;
GRANT user_role TO reviewer2;

CREATE USER editor1 IDENTIFIED BY 123;
GRANT user_role TO editor1;

-- GRANT SELECT, UPDATE ON / TO user_role;

GRANT create any trigger TO sec_admin;

CONN sec_admin/secadmin@localhost:1521/paperspdb;

-- Level Code	Level Name	    Ý nghĩa
-- 80	        SUBMITTING	    Giai đoạn nộp bài – thông tin còn được chỉnh sửa
-- 40	        REVIEWING	    Giai đoạn đánh giá – tài liệu nhạy cảm (review, comment)
-- 30	        ACCEPTANCE	    Giai đoạn xét duyệt accept/reject
-- 20	        EDITING	        Giai đoạn biên tập in ấn (camera-ready, unready, waiting)
-- 10	        CHECKED	        Hoàn tất – in ấn

BEGIN 
    sa_components.create_level ('ACCESS_PAPERS', 10, 'CHE', 'CHECKED');
    sa_components.create_level ('ACCESS_PAPERS', 20, 'EDT', 'EDITING');
    sa_components.create_level ('ACCESS_PAPERS', 25, 'LCK', 'LOCKED');  
    sa_components.create_level ('ACCESS_PAPERS', 30, 'ACC', 'ACCEPTANCE');
    sa_components.create_level ('ACCESS_PAPERS', 40, 'REV', 'REVIEWING');
    sa_components.create_level ('ACCESS_PAPERS', 50, 'CR', 'CAMERA_READY');  
    sa_components.create_level ('ACCESS_PAPERS', 60, 'WT', 'WAITING'); 
    sa_components.create_level ('ACCESS_PAPERS', 70, 'UR', 'UNREADY');    
    sa_components.create_level ('ACCESS_PAPERS', 80, 'SUB', 'SUBMITTING');
    sa_components.create_level ('ACCESS_PAPERS', 90, 'TSUB', 'TCSUBMITTING');
END;

select * from ALL_SA_LEVELS;

-- Code	    Compartment Name	    Ý nghĩa
-- 1	    AI	                    Trí tuệ nhân tạo
-- 2	    ML	                    Machine Learning
-- 3	    DS	                    Data Science
-- 4	    SE	                    Software Engineering
-- 5	    CYBER	                An ninh mạng
-- 6	    NETWORK	                Mạng máy tính
-- 7	    CV	                    Computer Vision

BEGIN
    sa_components.create_compartment ('ACCESS_PAPERS', 1, 'AI', 'ARTIFICIAL_INTELLIGENCE');
    sa_components.create_compartment ('ACCESS_PAPERS', 2, 'ML', 'MACHINE_LEARNING');
    sa_components.create_compartment ('ACCESS_PAPERS', 3, 'DS', 'DATA_SCIENCE');
    sa_components.create_compartment ('ACCESS_PAPERS', 4, 'SE', 'SOFTWARE_ENGINEERING');
    sa_components.create_compartment ('ACCESS_PAPERS', 5, 'CYB', 'CYBER_SECURITY');
    sa_components.create_compartment ('ACCESS_PAPERS', 6, 'NET', 'COMPUTER_NETWORKS');
    sa_components.create_compartment ('ACCESS_PAPERS', 7, 'CV', 'COMPUTER_VISION');
END;

select * from ALL_SA_COMPARTMENTS;

-- Code	    Group Name	        Ý nghĩa
-- 10	    PC	                PROGRAM CHAIR
-- 20	    EDT	                EDITORS
-- 30	    TC	                TRACK CHAIRS
-- 40	    RV	                REVIEWERS
-- 50	    AUT	                AUTHORS

BEGIN
    sa_components.create_group ('ACCESS_PAPERS', 10, 'PC', 'PROGRAM CHAIR');
    sa_components.create_group ('ACCESS_PAPERS', 20, 'EDT', 'EDITORS', 'PC');
    sa_components.create_group ('ACCESS_PAPERS', 30, 'TC', 'TRACK CHAIRS', 'EDT');
    sa_components.create_group ('ACCESS_PAPERS', 40, 'RV', 'REVIEWERS', 'TC');
    sa_components.create_group ('ACCESS_PAPERS', 50, 'AUT', 'AUTHORS', 'EDT');
END;

select * from ALL_SA_GROUPS;

---------------------------------------
BEGIN
    sa_label_admin.create_label ('ACCESS_PAPERS',10000,'CHE');
    sa_label_admin.create_label ('ACCESS_PAPERS',70000,'UR');
    sa_label_admin.create_label ('ACCESS_PAPERS',20000,'EDT'); 
    sa_label_admin.create_label ('ACCESS_PAPERS',30000,'ACC'); 
    sa_label_admin.create_label ('ACCESS_PAPERS',81050,'SUB:AI:AUT'); 
    sa_label_admin.create_label ('ACCESS_PAPERS',11054,'CHE:AI:AUT');
    sa_label_admin.create_label ('ACCESS_PAPERS',21054,'EDT:AI:AUT');
    sa_label_admin.create_label ('ACCESS_PAPERS',31054,'ACC:AI:AUT,RV');
    sa_label_admin.create_label ('ACCESS_PAPERS',41054,'REV:AI:AUT,RV');
    sa_label_admin.create_label ('ACCESS_PAPERS',51054,'CR:AI:AUT,RV');
    sa_label_admin.create_label ('ACCESS_PAPERS',61054,'WT:AI:AUT,RV');
    sa_label_admin.create_label ('ACCESS_PAPERS',71054,'UR:AI:AUT,RV');
    sa_label_admin.create_label ('ACCESS_PAPERS',26054,'LCK:AI:AUT,RV');
    sa_label_admin.create_label ('ACCESS_PAPERS',41004,'REV:AI:RV');
    sa_label_admin.create_label ('ACCESS_PAPERS',40000,'REV');
    sa_label_admin.create_label ('ACCESS_PAPERS',25000,'LCK');
END;
BEGIN
    sa_label_admin.create_label ('ACCESS_PAPERS',81020,'SUB:AI:EDT'); 
    sa_label_admin.create_label ('ACCESS_PAPERS',91030,'TSUB:AI:TC'); 
    sa_label_admin.create_label ('ACCESS_PAPERS',90000,'TSUB');
    sa_label_admin.create_label ('ACCESS_PAPERS',81053,'SUB:AI:AUT,TC'); 
END;
select * from ALL_SA_LABELS;


CONN papers_sec/paperssec@localhost:1521/paperspdb;

BEGIN
    sa_user_admin.set_user_labels(
        policy_name => 'ACCESS_PAPERS',
        user_name => 'AUTH1',
        max_read_label => 'SUB:AI:AUT',
        max_write_label => 'SUB:AI:AUT',
        min_write_label => 'UR',
        def_label => 'SUB:AI:AUT',
        row_label => 'SUB:AI:AUT');
END;
BEGIN
    sa_user_admin.set_user_labels(
        policy_name => 'ACCESS_PAPERS',
        user_name => 'reviewer1',
        max_read_label => 'REV:AI:RV',
        min_read_label => 'LCK',
        max_write_label => 'REV:AI:RV',
        min_write_label => 'REV',
        def_label => 'REV:AI:RV',
        row_label => 'REV:AI:RV');
END;

BEGIN
    sa_user_admin.set_user_labels(
        policy_name => 'ACCESS_PAPERS',
        user_name => 'editor1',
        max_read_label => 'SUB:AI:EDT',
        max_write_label => 'SUB:AI:EDT',
        min_write_label => 'EDT',
        def_label => 'SUB:AI:EDT',
        row_label => 'SUB:AI:EDT');
END;


BEGIN
    sa_user_admin.set_user_labels(
        policy_name => 'ACCESS_PAPERS',
        user_name => 'track_chair',
        max_read_label => 'TSUB:AI:TC',
        max_write_label => 'TSUB:AI:TC',
        min_write_label => 'TSUB',
        def_label => 'TSUB:AI:TC',
        row_label => 'TSUB:AI:TC');
END;

BEGIN
sa_user_admin.set_user_privs(
    policy_name => 'ACCESS_PAPERS',
    user_name => 'program_chair',
    PRIVILEGES => 'READ');
END;

BEGIN
sa_user_admin.set_user_privs(
    policy_name => 'ACCESS_PAPERS',
    user_name => 'papersadm',
    PRIVILEGES => 'FULL');
END;

BEGIN
sa_user_admin.set_user_privs(
    policy_name => 'ACCESS_PAPERS',
    user_name => 'papersadm',
    PRIVILEGES => 'FULL');
END;

BEGIN
sa_user_admin.set_user_privs(
    policy_name => 'ACCESS_PAPERS',
    user_name => 'sec_admin',
    PRIVILEGES => 'FULL');
END;

ALTER SESSION SET container = paperspdb;
select * from DBA_SA_USERS;
select * from DBA_SA_DATA_LABELS;

CONN sec_admin/secadmin@localhost:1521/paperspdb;

CREATE OR REPLACE TRIGGER trg_update_ols_level
BEFORE UPDATE OF paper_status ON papersadm.papers
FOR EACH ROW
DECLARE
    i_label NUMBER(10);
BEGIN
    IF :new.paper_status LIKE '%Submitting%' THEN
    i_label := 80000;
    ELSIF (:new.paper_status LIKE '%Locked%') OR (:new.paper_status LIKE '%Reviewing%') THEN
    i_label := 25000;
    ELSIF :new.paper_status LIKE '%Reviewed%' THEN
    i_label := 30000;
    ELSIF :new.paper_status LIKE '%Unready%' THEN
    i_label := 70000;
    ELSIF :new.paper_status LIKE '%Waiting%' THEN
    i_label := 60000;
    ELSIF :new.paper_status LIKE '%Camera-ready%' THEN
    i_label := 50000;
    ELSIF :new.paper_status LIKE '%Editing%' THEN
    i_label := 20000;
    ELSE
    i_label := 10000;
    END IF;

    i_label := i_label + 1000;

    IF (:new.paper_status LIKE '%Editing%') OR (:new.paper_status LIKE '%Checked%') THEN
    i_label := i_label + 50;
    ELSE
    i_label := i_label + 54;
    END IF;
    :new.ols_column := i_label;
END;

BEGIN
    sa_policy_admin.apply_table_policy(
        policy_name => 'ACCESS_PAPERS',
        schema_name => 'papersadm',
        table_name => 'papers',
        table_options => 'NO_CONTROL');
END;

CONN papersadm/pwd@localhost:1521/paperspdb;

DESCRIBE papers;

GRANT select, insert, update ON papers TO sec_admin;

CONN sec_admin/secadmin@localhost:1521/paperspdb;
UPDATE papersadm.papers SET ols_column = char_to_label('ACCESS_PAPERS', 'SUB');

Select * from papersadm.papers;

UPDATE papersadm.papers 
SET ols_column = char_to_label('ACCESS_PAPERS', 'SUB:AI:AUT,TC')
WHERE paper_status = 'Submitting'; 
UPDATE papersadm.papers 
SET ols_column = char_to_label('ACCESS_PAPERS', 'LCK:AI:AUT,RV')
WHERE paper_status = 'Locked' or paper_status = 'Reviewing';  
UPDATE papersadm.papers 
SET ols_column = char_to_label('ACCESS_PAPERS', 'ACC:AI:AUT,RV')
WHERE paper_status = 'Reviewed'; 
UPDATE papersadm.papers 
SET ols_column = char_to_label('ACCESS_PAPERS', 'UR:AI:AUT,RV')
WHERE paper_status = 'Unready'; 
 
UPDATE papersadm.papers 
SET ols_column = char_to_label('ACCESS_PAPERS', 'WT:AI:AUT,RV')
WHERE paper_status = 'Waiting';  
 
UPDATE papersadm.papers 
SET ols_column = char_to_label('ACCESS_PAPERS', 'CR:AI:AUT,RV')
WHERE paper_status = 'Camera-ready'; 
 
UPDATE papersadm.papers 
SET ols_column = char_to_label('ACCESS_PAPERS', 'EDT:AI:AUT')
WHERE paper_status = 'Editing';  
 
UPDATE papersadm.papers 
SET ols_column = char_to_label('ACCESS_PAPERS', 'CHE:AI:AUT')
WHERE paper_status = 'Checked'; 
COMMIT ;



BEGIN
    sa_policy_admin.remove_table_policy(
        policy_name => 'ACCESS_PAPERS',
        schema_name => 'papersadm',
        table_name => 'papers');

    sa_policy_admin.apply_table_policy(
        policy_name => 'ACCESS_PAPERS',
        schema_name => 'papersadm',
        table_name => 'papers',
        table_options =>'READ_CONTROL,WRITE_CONTROL,CHECK_CONTROL');
END;

Select * from papersadm.papers;
UPDATE papersadm.papers SET page_number =7 where paper_id = 4 ;

UPDATE papersadm.papers SET page_number = 90 where paper_id = 10 ;



ALTER SESSION SET container = paperspdb;