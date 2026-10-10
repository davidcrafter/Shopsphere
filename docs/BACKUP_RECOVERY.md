# Backup and recovery

1. Enable automated Supabase database backups for the production project and document the retention window.
2. Export a tested database backup before every forward migration and before destructive/archival catalog work.
3. Version storage assets or retain a separate copy of product imagery and policy/content exports.
4. Rehearse restore into a non-production project: database, storage paths, Auth redirect settings, and Edge Function secrets/configuration must be restored as a coordinated system.
5. Record migration version, deployment commit, recovery owner, and last restore drill in operational documentation.
6. Never restore test data over production. Keep production/staging/test Supabase projects and secrets separate.
