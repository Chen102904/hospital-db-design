-- ============================================================
-- 常用查询语句集（体现 SQL 能力）
-- 依赖：先执行 01_create_tables.sql 和 02_insert_data.sql
-- 注意：部分版本 Workbench 默认开启 safe update mode，
--       会拦截不带主键条件的 UPDATE/DELETE，故此处先关闭。
-- ============================================================
USE hospital_db;

-- 关闭安全更新模式（仅本次会话有效，避免 UPDATE/DELETE 被拦截）
SET SQL_SAFE_UPDATES = 0;

-- ------------------------------------------------------------
-- 一、基础查询（增删改查）
-- ------------------------------------------------------------

-- 1. 查询所有科室
SELECT * FROM department;

-- 2. 查询所有医生的姓名、职称、所属科室（多表联查）
SELECT d.doctor_id, d.doctor_name, d.title, dept.dept_name
FROM doctor d
LEFT JOIN department dept ON d.dept_id = dept.dept_id
ORDER BY dept.dept_name, d.doctor_id;

-- 3. 查询某位患者的挂号记录（按患者姓名）
SELECT p.patient_name, dept.dept_name, d.doctor_name,
       r.reg_date, r.reg_fee, r.reg_status
FROM registration r
JOIN patient p    ON r.patient_id = p.patient_id
JOIN doctor d     ON r.doctor_id  = d.doctor_id
JOIN department dept ON r.dept_id = dept.dept_id
WHERE p.patient_name = '陈小明';

-- 4. 新增一位患者
INSERT INTO patient (patient_name, gender, birth_date, phone, address)
VALUES ('周雨薇', '女', '1995-06-18', '13900000006', '杭州市余杭区XX路6号');

-- 5. 修改医生职称
UPDATE doctor SET title = '主任医师' WHERE doctor_name = '赵伟';

-- 6. 取消一条挂号记录
UPDATE registration SET reg_status = '已取消' WHERE reg_id = 6;

-- ------------------------------------------------------------
-- 二、统计查询（体现数据分析能力）
-- ------------------------------------------------------------

-- 7. 统计每个科室的医生人数
SELECT dept.dept_name AS 科室, COUNT(d.doctor_id) AS 医生人数
FROM department dept
LEFT JOIN doctor d ON dept.dept_id = d.dept_id
GROUP BY dept.dept_id, dept.dept_name
ORDER BY 医生人数 DESC;

-- 8. 统计各科室的挂号总量与挂号收入
SELECT dept.dept_name AS 科室,
       COUNT(r.reg_id) AS 挂号量,
       SUM(r.reg_fee)  AS 挂号收入
FROM department dept
LEFT JOIN registration r ON dept.dept_id = r.dept_id
GROUP BY dept.dept_id, dept.dept_name
ORDER BY 挂号收入 DESC;

-- 9. 查询挂号量最多的前 3 位医生
SELECT d.doctor_name AS 医生, dept.dept_name AS 科室,
       COUNT(r.reg_id) AS 接诊量
FROM doctor d
JOIN department dept ON d.dept_id = dept.dept_id
LEFT JOIN registration r ON d.doctor_id = r.doctor_id
GROUP BY d.doctor_id, d.doctor_name, dept.dept_name
ORDER BY 接诊量 DESC
LIMIT 3;

-- 10. 统计各职称的医生人数
SELECT title AS 职称, COUNT(*) AS 人数
FROM doctor
GROUP BY title;

-- 11. 查询库存低于 500 的药品（库存预警）
SELECT medicine_name AS 药品, spec AS 规格, stock AS 库存
FROM medicine
WHERE stock < 500
ORDER BY stock ASC;

-- 12. 查询某时间段内的挂号记录（日期范围查询）
SELECT r.reg_id, p.patient_name, r.reg_date
FROM registration r
JOIN patient p ON r.patient_id = p.patient_id
WHERE r.reg_date BETWEEN '2026-09-01 00:00:00' AND '2026-09-02 23:59:59';

-- ------------------------------------------------------------
-- 三、进阶查询（子查询 / 聚合 / 分页）
-- ------------------------------------------------------------

-- 13. 查询挂号费高于平均挂号费的记录（子查询）
SELECT r.reg_id, p.patient_name, r.reg_fee
FROM registration r
JOIN patient p ON r.patient_id = p.patient_id
WHERE r.reg_fee > (SELECT AVG(reg_fee) FROM registration);

-- 14. 查询每位患者的挂号次数
SELECT p.patient_name AS 患者, COUNT(r.reg_id) AS 挂号次数
FROM patient p
LEFT JOIN registration r ON p.patient_id = r.patient_id
GROUP BY p.patient_id, p.patient_name
ORDER BY 挂号次数 DESC;

-- 15. 查询有就诊记录的患者的病历详情（多表联查）
SELECT p.patient_name AS 患者, d.doctor_name AS 医生,
       m.visit_date AS 就诊时间, m.diagnosis AS 诊断
FROM medical_record m
JOIN patient p ON m.patient_id = p.patient_id
JOIN doctor d  ON m.doctor_id  = d.doctor_id
ORDER BY m.visit_date;

-- 16. 查询某份处方的药品明细与总金额
SELECT mr.record_id AS 病历号, p.patient_name AS 患者,
       med.medicine_name AS 药品, pd.quantity AS 数量,
       med.price AS 单价,
       pd.quantity * med.price AS 小计
FROM prescription_detail pd
JOIN medical_record mr ON pd.record_id = mr.record_id
JOIN patient p         ON mr.patient_id = p.patient_id
JOIN medicine med      ON pd.medicine_id = med.medicine_id
WHERE mr.record_id = 1;

-- 17. 分页查询：每页 3 条，查询第 2 页的挂号记录
SELECT r.reg_id, p.patient_name, r.reg_date
FROM registration r
JOIN patient p ON r.patient_id = p.patient_id
ORDER BY r.reg_id
LIMIT 3 OFFSET 3;
