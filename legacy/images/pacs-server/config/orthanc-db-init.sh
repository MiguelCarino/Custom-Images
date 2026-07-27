#!/usr/bin/env bash
# =============================================================================
# Orthanc PostgreSQL database initialisation
# Runs once at first boot via orthanc-db-init.service
# =============================================================================
set -euo pipefail

DB_NAME="orthanc"
DB_USER="orthanc"
# Read password from a secret file (create this at deploy time)
DB_PASS_FILE="/etc/orthanc/db.secret"

if [[ ! -f "$DB_PASS_FILE" ]]; then
  echo "ERROR: $DB_PASS_FILE not found. Create it with the DB password before first boot."
  exit 1
fi

DB_PASS=$(< "$DB_PASS_FILE")

# Wait for PostgreSQL to be ready
for i in $(seq 1 30); do
  pg_isready -q && break
  echo "Waiting for PostgreSQL... ($i/30)"
  sleep 2
done
pg_isready -q || { echo "PostgreSQL did not start"; exit 1; }

# Create user + database if they don't exist
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"

echo "Orthanc database initialised."

# Write Orthanc PostgreSQL plugin config
cat > /etc/orthanc/postgresql.json << EOF
{
  "PostgreSQL": {
    "EnableIndex": true,
    "EnableStorage": false,
    "Host": "localhost",
    "Port": 5432,
    "Database": "${DB_NAME}",
    "Username": "${DB_USER}",
    "Password": "${DB_PASS}",
    "EnableSsl": false,
    "Lock": false
  }
}
EOF

echo "PostgreSQL config written to /etc/orthanc/postgresql.json"

# Write env file consumed by the Orthanc quadlet
cat > /etc/orthanc/orthanc.env << EOF
ORTHANC__POSTGRESQL__HOST=host.containers.internal
ORTHANC__POSTGRESQL__PORT=5432
ORTHANC__POSTGRESQL__DATABASE=${DB_NAME}
ORTHANC__POSTGRESQL__USERNAME=${DB_USER}
ORTHANC__POSTGRESQL__PASSWORD=${DB_PASS}
ORTHANC__POSTGRESQL__ENABLE_INDEX=true
ORTHANC__POSTGRESQL__ENABLE_STORAGE=false
EOF
chmod 600 /etc/orthanc/orthanc.env
echo "Quadlet env file written to /etc/orthanc/orthanc.env"
