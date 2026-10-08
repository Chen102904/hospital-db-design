"""
用 SQLite 验证数据库设计逻辑（无需安装 MySQL）
说明：SQLite 语法与 MySQL 基本兼容，本项目仅用于本地验证表结构与查询逻辑。
"""
import sqlite3
import re

conn = sqlite3.connect(":memory:")
cur = conn.cursor()


def run_mysql_sql_as_sqlite(sql_text: str, label: str):
    """把 MySQL 语法粗略转换为 SQLite 可执行，逐条执行"""
    # 去掉 MySQL 专有语法
    sql_text = re.sub(r"DEFAULT CHARACTER SET \w+ COLLATE \w+", "", sql_text)
    sql_text = re.sub(r"DEFAULT CHARACTER SET \w+", "", sql_text)
    sql_text = re.sub(r"ENGINE=\w+", "", sql_text)
    sql_text = re.sub(r"COMMENT\s+'[^']*'", "", sql_text)
    sql_text = re.sub(r"COMMENT\s+'[^']*'", "", sql_text)
    sql_text = sql_text.replace("INT PRIMARY KEY AUTO_INCREMENT", "INTEGER PRIMARY KEY AUTOINCREMENT")
    sql_text = sql_text.replace("AUTO_INCREMENT", "AUTOINCREMENT")
    # 清理行内注释里的 -- 导致的分句问题
    sql_text = re.sub(r"--[^\n]*", "", sql_text)
    sql_text = sql_text.replace("DATETIME DEFAULT CURRENT_TIMESTAMP", "TEXT DEFAULT CURRENT_TIMESTAMP")

    # 移除 DROP DATABASE / CREATE DATABASE / USE
    lines = []
    for line in sql_text.split("\n"):
        s = line.strip()
        if s.upper().startswith("DROP DATABASE"):
            continue
        if s.upper().startswith("CREATE DATABASE"):
            continue
        if s.upper().startswith("USE "):
            continue
        lines.append(line)
    sql_text = "\n".join(lines)

    # 提取语句
    stmts = [s.strip() for s in sql_text.split(";") if s.strip()]
    ok, fail = 0, []
    for st in stmts:
        # 跳过 SQLite 不支持的 MySQL 专有语句
        if re.fullmatch(r"USE\s+\w+", st.strip(), flags=re.IGNORECASE):
            continue
        if re.match(r"SET\s+SQL_SAFE_UPDATES", st.strip(), flags=re.IGNORECASE):
            continue
        st = re.sub(r"^\s*USE\s+\w+\s*", "", st, flags=re.IGNORECASE).strip()
        if not st:
            continue
        try:
            cur.execute(st)
            ok += 1
        except Exception as e:
            fail.append((st[:60], str(e)))
    print(f"[{label}] 成功 {ok} 条，失败 {len(fail)} 条")
    for f in fail:
        print(f"   失败: {f[0]}... -> {f[1]}")
    return fail


print("=" * 60)
print("【第 1 步】建表")
print("=" * 60)
with open("01_create_tables.sql", encoding="utf-8") as f:
    create_sql = f.read()
fail1 = run_mysql_sql_as_sqlite(create_sql, "建表")

print()
print("=" * 60)
print("【第 2 步】插入测试数据")
print("=" * 60)
with open("02_insert_data.sql", encoding="utf-8") as f:
    insert_sql = f.read()
fail2 = run_mysql_sql_as_sqlite(insert_sql, "插入")

print()
print("=" * 60)
print("【第 3 步】数据核对")
print("=" * 60)
tables = ["department", "doctor", "patient", "registration",
          "medical_record", "medicine", "prescription_detail"]
for t in tables:
    cur.execute(f"SELECT COUNT(*) FROM {t}")
    print(f"  {t:<22} {cur.fetchone()[0]} 条")

print()
print("=" * 60)
print("【第 4 步】执行查询语句")
print("=" * 60)
with open("03_queries.sql", encoding="utf-8") as f:
    query_sql = f.read()

# 清除 SQL 注释（-- 开头），避免注释与语句粘连
query_sql = re.sub(r"--[^\n]*", "", query_sql)

# 逐条执行查询，展示结果
stmts = [s.strip() for s in query_sql.split(";") if s.strip()]
q_ok, q_fail = 0, []
for st in stmts:
    if st.upper().startswith("USE "):
        continue
    try:
        if re.fullmatch(r"USE\s+\w+", st.strip(), flags=re.IGNORECASE):
            continue
        if re.match(r"SET\s+SQL_SAFE_UPDATES", st.strip(), flags=re.IGNORECASE):
            continue
        st_clean = re.sub(r"^\s*USE\s+\w+\s*", "", st, flags=re.IGNORECASE).strip()
        if not st_clean:
            continue
        cur.execute(st_clean)
        rows = cur.fetchall()
        q_ok += 1
        if len(rows) > 0:
            head = st.replace("\n", " ")[:55]
            print(f"  查询成功({len(rows)}行): {head}...")
    except Exception as e:
        q_fail.append((st[:60], str(e)))

print(f"\n  查询语句：成功 {q_ok} 条，失败 {len(q_fail)} 条")
for f in q_fail:
    print(f"   失败: {f[0]}... -> {f[1]}")

conn.close()
print()
print("=" * 60)
if not fail1 and not fail2 and not q_fail:
    print("全部通过：数据库设计逻辑正确")
else:
    print("存在问题，请查看上方失败项")
print("=" * 60)
