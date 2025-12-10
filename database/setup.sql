-- ==================================================
-- FILE: setup.sql
-- Mô tả: Thiết lập User, Cấp quyền VPD và Tạo Context
-- File này có 2 phần. 
--        Phần 1 phải chạy bằng tài khoản SYS (hoặc SYSTEM).
--        Phần 2 chạy bằng tài khoản User dự án.
-- ==================================================

-- ==================================================
-- PHẦN 1: QUẢN TRỊ HỆ THỐNG (Chạy bởi SYS/SYSTEM)
-- ==================================================
-- 1. (Tùy chọn) Tạo User mới nếu chưa có
CREATE USER project_user IDENTIFIED BY password123;
GRANT CONNECT, RESOURCE TO project_user;
GRANT UNLIMITED TABLESPACE TO project_user;

-- 2. Cấp quyền tạo Context (Bắt buộc để chạy lệnh CREATE CONTEXT)
GRANT CREATE ANY CONTEXT TO project_user;

-- 3. Cấp quyền thực thi gói bảo mật VPD (Bắt buộc để chạy DBMS_RLS)
GRANT EXECUTE ON DBMS_RLS TO project_user;

-- 4. Cấp quyền xem phiên làm việc (Để dùng SYS_CONTEXT('USERENV'...))
GRANT SELECT ON V_$SESSION TO project_user;

-- ==================================================
-- PHẦN 2: THIẾT LẬP MÔI TRƯỜNG (Chạy bởi project_user)
-- ==================================================

-- 1. Tạo Context (Nơi lưu biến Session)
-- Lưu ý: 'pkg_security_context' là tên package sẽ quản lý context này
CREATE OR REPLACE CONTEXT MY_CTX USING pkg_security_context;

-- 2. Tạo Package để set giá trị cho Context
CREATE OR REPLACE PACKAGE pkg_security_context IS
    -- Thủ tục set giá trị (giả lập login)
    PROCEDURE set_context(p_attr VARCHAR2, p_val VARCHAR2);
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_security_context IS
    PROCEDURE set_context(p_attr VARCHAR2, p_val VARCHAR2) IS
    BEGIN
        -- Set giá trị vào namespace 'MY_CTX'
        DBMS_SESSION.SET_CONTEXT('MY_CTX', p_attr, p_val);
    END;
END;
/

-- 3. Cấp quyền thực thi Package cho Public (Nếu cần test từ user khác)
GRANT EXECUTE ON pkg_security_context TO PUBLIC;