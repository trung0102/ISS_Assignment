-- ==================================================
-- FILE: testcase.sql
-- Mô tả: Kiểm thử các kịch bản phân quyền
-- ==================================================

SET LINESIZE 200;
SET PAGESIZE 100;
COLUMN content FORMAT A20;
COLUMN user_email FORMAT A20;

-- TESTCASE 1: REVIEWER (ID=20)
-- Mong doi: Chi thay cac Review do minh viet (ID=20)
EXEC pkg_security_context.set_context('CTX_USER_ID', '20');
EXEC pkg_security_context.set_context('ROLE', 'REVIEWER');
SELECT * FROM REVIEWS;


-- TESTCASE 2: AUTHOR (ID=10)
-- Mong doi:
-- Thay Review cua bai 100 ('Reviewed')
-- KHONG thay Review bai 101 ('Submitted')
-- KHONG thay Review bai 200 (Cua nguoi khac)
EXEC pkg_security_context.set_context('CTX_USER_ID', '10');
EXEC pkg_security_context.set_context('ROLE', 'AUTHOR');
SELECT * FROM REVIEWS;


-- TESTCASE 3: USER PRIVACY (AUTHOR ID=10)
-- Mong doi: Chi thay thong tin cua chinh minh
EXEC pkg_security_context.set_context('CTX_SEARCH_EMAIL', ''); 
SELECT * FROM USERS;

-- TESTCASE 4: TIM KIEM DONG TAC GIA (AUTHOR ID=10)
-- Nhap dung email 'reviewer@uni.edu'
-- Mong muon: Thay minh (ID=10) VA dong nghiep (ID=20)
EXEC pkg_security_context.set_context('CTX_SEARCH_EMAIL', 'reviewer@uni.edu');
SELECT * FROM USERS;


-- TESTCASE 5: CHAIR (ID=1)
-- Mong muon: Thay toan bo du lieu
EXEC pkg_security_context.set_context('ROLE', 'CHAIR');
SELECT * FROM REVIEWS;
SELECT * FROM USERS;