import os
import psycopg2

db_password = os.environ['DB_PASSWORD']
stripe_key = os.environ['STRIPE_KEY']

print("DB_PASSWORD received, length:", len(db_password))
print("STRIPE_KEY received, length:", len(stripe_key))

conn = psycopg2.connect(
    host="localhost",
    port=8432,
    dbname="billing",
    user="billing_app",
    password=db_password
)
cur = conn.cursor()
cur.execute("INSERT INTO transactions (description) VALUES (%s) RETURNING id;",
            ("Transaction via Summon-injected credential",))
new_id = cur.fetchone()[0]
conn.commit()
cur.execute("SELECT id, description FROM transactions WHERE id = %s;", (new_id,))
print("Wrote and read back row:", cur.fetchone())
cur.close()
conn.close()
