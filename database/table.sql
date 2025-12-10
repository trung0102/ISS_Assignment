-- ==================================================
-- FILE: table.sql
-- Mô tả: Tạo bảng
-- ==================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE REVIEWS CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE PAPERS CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE USERS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- 1. Tạo bảng
CREATE TABLE USERS (
    user_id NUMBER PRIMARY KEY,
    fullname VARCHAR2(100),
    user_email VARCHAR2(100),
    role VARCHAR2(50) -- 'AUTHOR', 'REVIEWER', 'CHAIR', 'EDITOR'
);

CREATE TABLE PAPERS (
    paper_id NUMBER PRIMARY KEY,
    title VARCHAR2(200),
    submitter_id NUMBER,
    paper_status VARCHAR2(50), 
    CONSTRAINT fk_paper_author FOREIGN KEY (submitter_id) REFERENCES USERS(user_id)
);

CREATE TABLE REVIEWS (
    review_id NUMBER PRIMARY KEY,
    paper_id NUMBER,
    user_id NUMBER, -- Reviewer ID
    content VARCHAR2(2000),
    score NUMBER,
    CONSTRAINT fk_review_paper FOREIGN KEY (paper_id) REFERENCES PAPERS(paper_id),
    CONSTRAINT fk_review_user FOREIGN KEY (user_id) REFERENCES USERS(user_id)
);

-- 2. INSERT DỮ LIỆU

-- === CHAIR (Ban Quản Trị) ===
INSERT INTO USERS VALUES (1, 'Tong Giam Doc (Chair)', 'chair@conf.org', 'CHAIR');
INSERT INTO USERS VALUES (2, 'Pho Chu Tich (Vice Chair)', 'vice@conf.org', 'CHAIR');

-- === EDITORS (Ban Biên Tập) ===
INSERT INTO USERS VALUES (40, 'Le Bien Tap (Editor A)', 'editor1@conf.org', 'EDITOR');
INSERT INTO USERS VALUES (41, 'Pham Kiem Duyet (Editor B)', 'editor2@conf.org', 'EDITOR');

-- === AUTHORS (Tác Giả) ===
INSERT INTO USERS VALUES (10, 'Nguyen Van Author 1', 'au1@uni.edu', 'AUTHOR');
INSERT INTO USERS VALUES (11, 'Tran Van Author 2', 'au2@uni.edu', 'AUTHOR');
INSERT INTO USERS VALUES (12, 'Le Thi Author 3', 'au3@uni.edu', 'AUTHOR');

-- === REVIEWERS (Phản Biện) ===
INSERT INTO USERS VALUES (20, 'Tien Si Reviewer 1', 'rev1@uni.edu', 'REVIEWER');
INSERT INTO USERS VALUES (21, 'Giao Su Reviewer 2', 'rev2@uni.edu', 'REVIEWER');
INSERT INTO USERS VALUES (22, 'Thac Si Reviewer 3', 'rev3@uni.edu', 'REVIEWER');


-- 3. INSERT BÀI BÁO

-- Bài 100 (Của Author 1): Đang chấm, chưa có kết quả
INSERT INTO PAPERS VALUES (100, 'Nghien cuu AI trong Y te', 10, 'Reviewing');

-- Bài 101 (Của Author 1): Mới nộp
INSERT INTO PAPERS VALUES (101, 'Ung dung Blockchain vao Logictics', 10, 'Submitting');

-- Bài 200 (Của Author 2): Đã công bố (Author 2 xem được review)
INSERT INTO PAPERS VALUES (200, 'An ninh mang 2025', 11, 'Reviewed');

-- Bài 300 (Của Author 3): Cần sửa lại
INSERT INTO PAPERS VALUES (300, 'Du lieu lon (Big Data)', 12, 'Camera-ready');


-- 4. INSERT REVIEWS

-- Reviewer 1 chấm bài 200 (đã public) -> Author 2 sẽ thấy dòng này
INSERT INTO REVIEWS VALUES (500, 200, 20, 'Bai viet xuat sac, dong y dang', 9);

-- Reviewer 2 cũng chấm bài 200 -> Author 2 thấy dòng này
INSERT INTO REVIEWS VALUES (501, 200, 21, 'Can bo sung tai lieu tham khao', 7);

-- Reviewer 1 chấm bài 100 (đang chấm) -> Author 1 KHÔNG thấy (vì chưa Reviewed)
INSERT INTO REVIEWS VALUES (502, 100, 20, 'Dang xem xet ky thuat', null);

COMMIT;