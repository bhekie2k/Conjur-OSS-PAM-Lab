import psycopg2

conn = psycopg2.connect(
    "host=localhost port=5432 dbname=billing user=billing_app sslmode=disable"
)
cur = conn.cursor()
cur.execute("INSERT INTO transactions (description) VALUES (%s) RETURNING id;",
            ("Transaction via Secretless broker",))
new_id = cur.fetchone()[0]
conn.commit()
cur.execute("SELECT id, description FROM transactions WHERE id = %s;", (new_id,))
print("Wrote and read back row:", cur.fetchone())
cur.close()
conn.close()
