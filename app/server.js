const express = require('express');
const oracledb = require('oracledb');
const bodyParser = require('body-parser');
const session = require('express-session');
const app = express();
const PORT = 3000;

// Cấu hình kết nối
const dbConfig = { user: "project_user", password: "password123", connectString: "localhost/xepdb1" };

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static('public'));
app.use(session({ secret: 'iss_secret', resave: false, saveUninitialized: true }));

// Helper bật VPD
async function getVpdConnection(req) {
     let conn;
     try {
          conn = await oracledb.getConnection(dbConfig);
          const userId = req.session.userId;
          if (userId) {
               // Set ID vào Context
               await conn.execute(`BEGIN pkg_security_context.set_context('CTX_USER_ID', :id); END;`, { id: userId });

               // Lấy Role từ DB set vào Context
               const result = await conn.execute(`SELECT role FROM USERS WHERE user_id = :id`, [userId]);
               if (result.rows.length > 0) {
                    const role = result.rows[0][0];
                    await conn.execute(`BEGIN pkg_security_context.set_context('ROLE', :r); END;`, { r: role });
               }
          }
          return conn;
     } catch (err) { console.error('[DB CONNECT ERROR]:', err); throw err; }
}

app.post('/login', (req, res) => { req.session.userId = req.body.user_id; res.redirect('/papers.html'); });
app.get('/api/whoami', async (req, res) => {

     let conn;
     try {
          conn = await oracledb.getConnection(dbConfig);
          const userId = req.session.userId;
          if (!userId) return res.json({ role: 'GUEST' });
          const result = await conn.execute(`SELECT role FROM USERS WHERE user_id = :id`, [userId], { outFormat: oracledb.OUT_FORMAT_OBJECT });
          const role = result.rows.length > 0 ? result.rows[0].ROLE : 'GUEST';
          res.json({ id: userId, role: role });
     } catch (err) { res.status(500).json({ error: err.message }); } finally { if (conn) await conn.close(); }
});

app.get('/api/users-list', async (req, res) => {
     let conn; try {
          conn = await oracledb.getConnection(dbConfig);
          const result = await conn.execute(`SELECT user_id, fullname, role FROM USERS ORDER BY role, user_id`, [], { outFormat: oracledb.OUT_FORMAT_OBJECT });
          res.json(result.rows);
     } catch (e) { res.status(500).json(e); } finally { if (conn) await conn.close(); }
});

app.get('/api/papers', async (req, res) => {
     let conn;
     try {
          conn = await getVpdConnection(req);
          const result = await conn.execute(`SELECT paper_id, title, paper_status FROM PAPERS ORDER BY paper_id ASC`, [], { outFormat: oracledb.OUT_FORMAT_OBJECT });
          res.json(result.rows);
     } catch (err) { res.status(500).json({ error: err.message }); } finally { if (conn) await conn.close(); }
});

app.get('/api/reviews', async (req, res) => {
     let conn;
     try {
          conn = await getVpdConnection(req);
          const result = await conn.execute(`SELECT * FROM REVIEWS ORDER BY paper_id ASC`, [], { outFormat: oracledb.OUT_FORMAT_OBJECT });
          res.json(result.rows);
     } catch (err) { res.status(500).json({ error: err.message }); } finally { if (conn) await conn.close(); }
});

// === API AUTHOR SỬA BÀI (Có kiểm tra trạng thái) ===
app.post('/api/papers/edit', async (req, res) => {
     let conn;
     try {
          conn = await getVpdConnection(req);
          const { paper_id, new_title } = req.body;

          // 1. Kiểm tra trạng thái hiện tại
          const check = await conn.execute(
               `SELECT paper_status FROM PAPERS WHERE paper_id = :id`,
               [paper_id]
          );

          if (check.rows.length === 0) throw new Error("Không tìm thấy bài báo!");
          const currentStatus = check.rows[0][0];

          // 2. Chỉ cho sửa khi Submitting hoặc Revision
          if (currentStatus !== 'Submitting' && currentStatus !== 'Revision') {
               throw new Error(`Không thể sửa bài khi đang ở trạng thái: ${currentStatus}`);
          }

          // 3. Thực hiện Update
          await conn.execute(
               `UPDATE PAPERS SET title = :t WHERE paper_id = :id`,
               { t: new_title, id: paper_id },
               { autoCommit: true }
          );
          res.json({ success: true, message: "Cập nhật tiêu đề thành công!" });

     } catch (err) { console.error(err); res.status(500).json({ success: false, message: err.message }); }
     finally { if (conn) await conn.close(); }
});

// API REVIEWER CHẤM ĐIỂM (Có kiểm tra trạng thái) ===
app.post('/api/reviews/submit', async (req, res) => {
     let conn;
     try {
          conn = await getVpdConnection(req);
          const { paper_id, score, content } = req.body;
          const userId = req.session.userId;

          // 1. Kiểm tra trạng thái bài báo
          const pCheck = await conn.execute(`SELECT paper_status FROM PAPERS WHERE paper_id = :id`, [paper_id]);
          if (pCheck.rows.length === 0) throw new Error("Bài báo không tồn tại");

          const pStatus = pCheck.rows[0][0];
          if (pStatus !== 'Reviewing') {
               throw new Error("Chỉ được phép chấm điểm khi bài báo đang ở trạng thái REVIEWING!");
          }

          // 2. Kiểm tra xem đã chấm chưa
          const rCheck = await conn.execute(
               `SELECT review_id FROM REVIEWS WHERE paper_id = :pid AND user_id = :userid`,
               { pid: paper_id, userid: userId }
          );

          if (rCheck.rows.length > 0) {
               // UPDATE
               await conn.execute(
                    `UPDATE REVIEWS SET score = :s, content = :c WHERE paper_id = :pid AND user_id = :userid`,
                    { s: score, c: content, pid: paper_id, userid: userId },
                    { autoCommit: true }
               );
          } else {
               // INSERT
               const idRes = await conn.execute(`SELECT NVL(MAX(review_id), 0) + 1 FROM REVIEWS`);
               const newId = idRes.rows[0][0];

               await conn.execute(
                    `INSERT INTO REVIEWS (review_id, paper_id, user_id, content, score) 
                  VALUES (:rid, :pid, :userid, :c, :s)`,
                    { rid: newId, pid: paper_id, userid: userId, c: content, s: score },
                    { autoCommit: true }
               );
          }
          res.json({ success: true });
     } catch (err) {
          console.error(err);
          res.status(500).json({ success: false, message: err.message });
     }
     finally {
          if (conn) await conn.close();
     }
});

// API EDITOR UPDATE
app.post('/api/papers/update', async (req, res) => {
     let conn;
     try {
          conn = await getVpdConnection(req);
          const { paper_id, status } = req.body;
          await conn.execute(`UPDATE PAPERS SET paper_status = :s WHERE paper_id = :id`, { s: status, id: paper_id }, { autoCommit: true });
          res.json({ success: true });
     } catch (err) { res.status(500).json({ success: false, message: err.message }); } finally { if (conn) await conn.close(); }
});

app.listen(PORT, () => { console.log(`Server running at http://localhost:${PORT}/login.html`); });