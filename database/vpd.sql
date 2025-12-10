-- ==================================================
-- FILE: vpd.sql
-- Mô tả: Tách biệt chính sách ĐỌC và GHI cho Reviews
-- ==================================================

-- 1. Hàm chính sách ĐỌC (SELECT)
-- Reviewer thấy bài mình, Tác giả thấy bài mình (nếu đã public)
CREATE OR REPLACE FUNCTION fn_vpd_reviews_read (
    p_schema IN VARCHAR2, 
    p_object IN VARCHAR2
) RETURN VARCHAR2 
AS
    v_role VARCHAR2(50);
BEGIN
    v_role := SYS_CONTEXT('MY_CTX', 'ROLE');
    IF v_role IN ('CHAIR', 'EDITOR') THEN RETURN NULL; END IF;

    RETURN 'user_id = SYS_CONTEXT(''MY_CTX'', ''CTX_USER_ID'') 
            OR paper_id IN (
                SELECT paper_id FROM PAPERS 
                WHERE submitter_id = SYS_CONTEXT(''MY_CTX'', ''CTX_USER_ID'')
                  AND paper_status IN (''Reviewed'', ''Camera-ready'', ''Checked'')
            )';
END;
/

-- 2. Hàm chính sách GHI (INSERT, UPDATE, DELETE)
-- Chỉ cho phép thao tác trên dữ liệu CỦA CHÍNH MÌNH (User_ID trùng khớp)
-- Tác giả KHÔNG được phép sửa/xóa review của người khác dù họ nhìn thấy.
CREATE OR REPLACE FUNCTION fn_vpd_reviews_write (
    p_schema IN VARCHAR2, 
    p_object IN VARCHAR2
) RETURN VARCHAR2 
AS
    v_role VARCHAR2(50);
BEGIN
    v_role := SYS_CONTEXT('MY_CTX', 'ROLE');
    IF v_role IN ('CHAIR', 'EDITOR') THEN RETURN NULL; END IF;

    -- Chỉ được sửa/xóa dòng nào mà cột user_id trùng với mình
    RETURN 'user_id = SYS_CONTEXT(''MY_CTX'', ''CTX_USER_ID'')';
END;
/

-- 3. Áp dụng chính sách (Xóa cái cũ, thêm cái mới)
BEGIN
    -- Gỡ bỏ chính sách cũ (nếu có)
    BEGIN DBMS_RLS.DROP_POLICY(USER, 'REVIEWS', 'POL_REVIEW_ACCESS'); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN DBMS_RLS.DROP_POLICY(USER, 'REVIEWS', 'POL_REVIEW_READ'); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN DBMS_RLS.DROP_POLICY(USER, 'REVIEWS', 'POL_REVIEW_WRITE'); EXCEPTION WHEN OTHERS THEN NULL; END;

    -- 3.1. Chính sách SELECT (Dùng hàm read)
    DBMS_RLS.ADD_POLICY (
        object_schema    => USER,
        object_name      => 'REVIEWS',
        policy_name      => 'POL_REVIEW_READ',
        policy_function  => 'fn_vpd_reviews_read',
        statement_types  => 'SELECT'
    );

    -- 3.2. Chính sách INSERT, UPDATE, DELETE (Dùng hàm write)
    DBMS_RLS.ADD_POLICY (
        object_schema    => USER,
        object_name      => 'REVIEWS',
        policy_name      => 'POL_REVIEW_WRITE',
        policy_function  => 'fn_vpd_reviews_write',
        statement_types  => 'INSERT,UPDATE,DELETE',
        update_check     => TRUE
    );
END;
/