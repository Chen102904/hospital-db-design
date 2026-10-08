-- ============================================================
-- 医院信息管理系统 数据库设计
-- 数据库：hospital_db
-- 说明：包含患者、医生、科室、挂号、病历、药品等核心业务表
-- 作者：陈嘉岩
-- ============================================================

DROP DATABASE IF EXISTS hospital_db;
CREATE DATABASE hospital_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE hospital_db;

-- ------------------------------------------------------------
-- 1. 科室表 department
-- ------------------------------------------------------------
CREATE TABLE department (
    dept_id       INT PRIMARY KEY AUTO_INCREMENT COMMENT '科室编号',
    dept_name     VARCHAR(50)  NOT NULL COMMENT '科室名称',
    dept_location VARCHAR(100) COMMENT '科室位置',
    dept_phone    VARCHAR(20)  COMMENT '科室电话',
    create_time   DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) COMMENT '科室信息表';

-- ------------------------------------------------------------
-- 2. 医生表 doctor
-- ------------------------------------------------------------
CREATE TABLE doctor (
    doctor_id     INT PRIMARY KEY AUTO_INCREMENT COMMENT '医生编号',
    doctor_name   VARCHAR(30)  NOT NULL COMMENT '医生姓名',
    gender        CHAR(1)      NOT NULL COMMENT '性别：男/女',
    title         VARCHAR(20)  COMMENT '职称：主任医师/副主任医师/主治医师/住院医师',
    dept_id       INT          COMMENT '所属科室编号',
    specialty     VARCHAR(100) COMMENT '擅长领域',
    phone         VARCHAR(20)  COMMENT '联系电话',
    create_time   DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '入职/创建时间',
    CONSTRAINT fk_doctor_dept FOREIGN KEY (dept_id) REFERENCES department(dept_id)
) COMMENT '医生信息表';

-- ------------------------------------------------------------
-- 3. 患者表 patient
-- ------------------------------------------------------------
CREATE TABLE patient (
    patient_id      INT PRIMARY KEY AUTO_INCREMENT COMMENT '患者编号',
    patient_name    VARCHAR(30)  NOT NULL COMMENT '患者姓名',
    gender          CHAR(1)      NOT NULL COMMENT '性别：男/女',
    birth_date      DATE         COMMENT '出生日期',
    id_card         VARCHAR(18)  UNIQUE COMMENT '身份证号',
    phone           VARCHAR(20)  COMMENT '联系电话',
    address         VARCHAR(200) COMMENT '家庭住址',
    create_time     DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '建档时间'
) COMMENT '患者信息表';

-- ------------------------------------------------------------
-- 4. 挂号表 registration
-- ------------------------------------------------------------
CREATE TABLE registration (
    reg_id        INT PRIMARY KEY AUTO_INCREMENT COMMENT '挂号编号',
    patient_id    INT          NOT NULL COMMENT '患者编号',
    doctor_id     INT          NOT NULL COMMENT '医生编号',
    dept_id       INT          NOT NULL COMMENT '科室编号',
    reg_date      DATETIME     NOT NULL COMMENT '挂号时间',
    reg_fee       DECIMAL(8,2) NOT NULL DEFAULT 0.00 COMMENT '挂号费',
    reg_status    VARCHAR(10)  NOT NULL DEFAULT '已挂号' COMMENT '状态：已挂号/已就诊/已取消',
    CONSTRAINT fk_reg_patient FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
    CONSTRAINT fk_reg_doctor  FOREIGN KEY (doctor_id)  REFERENCES doctor(doctor_id),
    CONSTRAINT fk_reg_dept    FOREIGN KEY (dept_id)    REFERENCES department(dept_id)
) COMMENT '挂号记录表';

-- ------------------------------------------------------------
-- 5. 病历表 medical_record
-- ------------------------------------------------------------
CREATE TABLE medical_record (
    record_id     INT PRIMARY KEY AUTO_INCREMENT COMMENT '病历编号',
    patient_id    INT          NOT NULL COMMENT '患者编号',
    doctor_id     INT          NOT NULL COMMENT '接诊医生编号',
    reg_id        INT          COMMENT '关联挂号编号',
    visit_date    DATETIME     NOT NULL COMMENT '就诊时间',
    diagnosis     VARCHAR(200) COMMENT '诊断结果',
    prescription  TEXT         COMMENT '处方内容',
    remark        VARCHAR(200) COMMENT '备注',
    CONSTRAINT fk_record_patient FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
    CONSTRAINT fk_record_doctor  FOREIGN KEY (doctor_id)  REFERENCES doctor(doctor_id),
    CONSTRAINT fk_record_reg     FOREIGN KEY (reg_id)     REFERENCES registration(reg_id)
) COMMENT '病历记录表';

-- ------------------------------------------------------------
-- 6. 药品表 medicine
-- ------------------------------------------------------------
CREATE TABLE medicine (
    medicine_id   INT PRIMARY KEY AUTO_INCREMENT COMMENT '药品编号',
    medicine_name VARCHAR(100) NOT NULL COMMENT '药品名称',
    spec          VARCHAR(50)  COMMENT '规格',
    unit          VARCHAR(10)  COMMENT '单位',
    price         DECIMAL(8,2) NOT NULL COMMENT '单价',
    stock         INT          NOT NULL DEFAULT 0 COMMENT '库存数量',
    manufacturer  VARCHAR(100) COMMENT '生产厂家'
) COMMENT '药品信息表';

-- ------------------------------------------------------------
-- 7. 处方明细表 prescription_detail
-- ------------------------------------------------------------
CREATE TABLE prescription_detail (
    detail_id     INT PRIMARY KEY AUTO_INCREMENT COMMENT '明细编号',
    record_id     INT           NOT NULL COMMENT '病历编号',
    medicine_id   INT           NOT NULL COMMENT '药品编号',
    quantity      INT           NOT NULL COMMENT '数量',
    dosage        VARCHAR(100)  COMMENT '用法用量',
    CONSTRAINT fk_detail_record   FOREIGN KEY (record_id)   REFERENCES medical_record(record_id),
    CONSTRAINT fk_detail_medicine FOREIGN KEY (medicine_id) REFERENCES medicine(medicine_id)
) COMMENT '处方明细表';

-- ------------------------------------------------------------
-- 索引（提升常用查询性能）
-- ------------------------------------------------------------
CREATE INDEX idx_reg_date      ON registration(reg_date);
CREATE INDEX idx_record_date   ON medical_record(visit_date);
CREATE INDEX idx_patient_phone ON patient(phone);
CREATE INDEX idx_doctor_dept   ON doctor(dept_id);
