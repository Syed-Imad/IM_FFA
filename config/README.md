# UniLearn Hub -- config

PostgreSQL security configuration for the UniLearn Hub database.

## Files

**postgresql.conf**
Server-wide settings. Restricts network exposure (`listen_addresses`),
turns on SSL, sets stronger password hashing (`scram-sha-256`),
enables full write logging (`log_statement = mod`) for audit purposes,
and keeps autovacuum on so dead rows from updates/deletes don't
linger on disk.

**pg_hba.conf**
Controls who can connect, from where, and how. Local/loopback
connections must authenticate with `scram-sha-256`. Only a specific
trusted subnet is allowed to connect remotely, and only over SSL
(`hostssl`, not `host`). Everything else is explicitly rejected --
the database is not reachable from the open internet.

**server.key / server.crt**
Self-signed key/cert pair, backs the SSL that `postgresql.conf` and
`pg_hba.conf` require. `server.key` is in the coursework submission
zip but left out of this public GitHub repo, since a real private key
has no business being published even when it's a coursework
placeholder.

## Installation

1. Copy all four files into the PostgreSQL data directory (found via
   `SHOW data_directory;` on an existing install, or the `-D` path
   passed to `initdb`).
2. Set correct permissions on the private key:
   `chmod 600 server.key`
3. Restart PostgreSQL for the settings to take effect:
   `pg_ctl restart -D <data_directory>`

## Notes

- `10.20.1.0/24` in `pg_hba.conf` is illustrative -- stands in for a
  segmented app-tier subnet, not a real deployed range. Replace before
  deploying.
- Self-signed cert: encrypts, but isn't verifiable like a CA-signed
  one.
- `CREATE ROLE` passwords in `schema.sql` are placeholders, not real
  credentials.
- Tested against a live PostgreSQL 18 instance: SSL, `scram-sha-256`,
  and `log_statement=mod` all confirmed working; plaintext (non-SSL)
  connections correctly rejected by `pg_hba.conf`.
