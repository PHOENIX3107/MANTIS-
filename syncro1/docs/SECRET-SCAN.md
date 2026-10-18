# Full-history secret scan

Command executed against a fresh local clone containing all reachable git
history and refs:

```text
docker run --rm -v "$scan_dir/repo:/repo:ro" zricethezav/gitleaks:v8.24.2 detect --source=/repo --log-opts='--all' --redact --no-banner
```

Observed output:

```text
4 commits scanned.
scanned ~15808191 bytes (15.81 MB) in 1.51s
no leaks found
secret_scan_exit=0
```

The ignored working-tree `.env` was not part of the clone or scan.
