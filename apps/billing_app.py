import os
import asyncio
from conjur_api import Client
from conjur_api.models import SslVerificationMode, ConjurConnectionInfo, CredentialsData
from conjur_api.providers import SimpleCredentialsProvider, AuthnAuthenticationStrategy
import psycopg2

CONJUR_URL = "https://localhost:8443"
ACCOUNT = "myConjurAccount"
ROLE_ID = "host/prod/billing-app/billing-app-01"
API_KEY = os.environ["API_KEY"]
CERT_FILE = "./conjur-server.pem"

connection_info = ConjurConnectionInfo(
    conjur_url=CONJUR_URL,
    account=ACCOUNT,
    cert_file=CERT_FILE
)

credentials = CredentialsData(username=ROLE_ID, api_key=API_KEY, machine=CONJUR_URL)
credentials_provider = SimpleCredentialsProvider()
credentials_provider.save(credentials)

authn_provider = AuthnAuthenticationStrategy(credentials_provider)

client = Client(
    connection_info,
    authn_strategy=authn_provider,
    ssl_verification_mode=SslVerificationMode.SELF_SIGN
)

async def main():
    db_password_bytes = await client.get("prod/billing-app/db/password")
    db_password = db_password_bytes.decode('utf-8')
    print("Retrieved secret from Conjur, length:", len(db_password))

    conn = psycopg2.connect(
        host="localhost",
        port=8432,
        dbname="billing",
        user="billing_app",
        password=db_password
    )
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS transactions (id SERIAL PRIMARY KEY, description TEXT);")
    cur.execute(
        "INSERT INTO transactions (description) VALUES (%s) RETURNING id;",
        ("Test transaction via Conjur-fetched credential",)
    )
    new_id = cur.fetchone()[0]
    conn.commit()

    cur.execute("SELECT id, description FROM transactions WHERE id = %s;", (new_id,))
    print("Successfully wrote and read back row:", cur.fetchone())

    cur.close()
    conn.close()

asyncio.run(main())
