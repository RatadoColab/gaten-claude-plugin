# Referência: domains/security/SKILL.md — Seção A03 (Injection)
# Quando usar: prevenção de SQL injection e command injection em Python

# SQL Injection — ERRADO
# query = f"SELECT * FROM users WHERE username = '{username}'"

# SQL Injection — CORRETO (parametrizado)
import cursor  # placeholder — use o cursor do seu driver (psycopg2, sqlite3, etc.)

query = "SELECT * FROM users WHERE username = %s"
cursor.execute(query, (username,))

# Command Injection — ERRADO
# import subprocess
# subprocess.run(f"ls {user_input}", shell=True)

# Command Injection — CORRETO
import subprocess

# Pass arguments as a list; never use shell=True with user input
subprocess.run(["ls", user_input], shell=False)
