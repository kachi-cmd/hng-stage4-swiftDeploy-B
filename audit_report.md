# swiftdeploy Audit Report

Generated: 2026-05-06T20:06:05Z
Period: `2026-05-06T16:23:42Z` → `2026-05-06T20:05:32Z`
Total entries: 21

## Summary

| Metric | Value |
|--------|-------|
| Total scrapes | 21 |
| Time in stable | 3 scrapes |
| Time in canary | 18 scrapes |
| Avg P99 latency | 5.0ms |
| Max P99 latency | 5.0ms |
| Avg error rate | 0.000% |
| Total violations | 26 |

## Timeline

| Timestamp | Event | Mode | Detail |
|-----------|-------|------|--------|
| `2026-05-06T16:23:42Z` | Stack started | stable | Initial state — mode=stable |
| `2026-05-06T20:02:35Z` | Mode changed | canary | stable → canary |
| `2026-05-06T20:05:01Z` | Chaos injected | canary | chaos_active=1 (slow) |

## Policy Violations

| Timestamp | Mode | Violation | P99 (ms) | Error Rate |
|-----------|------|-----------|----------|------------|
| `2026-05-06T16:23:42Z` | stable | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T16:23:47Z` | stable | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T16:23:52Z` | stable | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:02:35Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:02:40Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:02:45Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:02:50Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:02:55Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:03:00Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:03:05Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:03:10Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:03:16Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:03:21Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:03:26Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:05:01Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:05:01Z` | canary | [policy/canary] Sample size 7 is too small for reliable measurement (need >= 10) | 5 | 0.000% |
| `2026-05-06T20:05:07Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:05:07Z` | canary | [policy/canary] Sample size 8 is too small for reliable measurement (need >= 10) | 5 | 0.000% |
| `2026-05-06T20:05:12Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:05:12Z` | canary | [policy/canary] Sample size 8 is too small for reliable measurement (need >= 10) | 5 | 0.000% |
| `2026-05-06T20:05:17Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:05:17Z` | canary | [policy/canary] Sample size 9 is too small for reliable measurement (need >= 10) | 5 | 0.000% |
| `2026-05-06T20:05:22Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:05:22Z` | canary | [policy/canary] Sample size 9 is too small for reliable measurement (need >= 10) | 5 | 0.000% |
| `2026-05-06T20:05:27Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |
| `2026-05-06T20:05:32Z` | canary | [policy/infra] Disk free 3.5GB is below minimum 10.0GB | 5 | 0.000% |

## Recent Metrics (last 5 scrapes)

| Timestamp | Mode | Req/s | P99 (ms) | Error Rate | Chaos |
|-----------|------|-------|----------|------------|-------|
| `2026-05-06T20:05:12Z` | canary | 0.00 | 5 | 0.000% | slow |
| `2026-05-06T20:05:17Z` | canary | 0.20 | 5 | 0.000% | slow |
| `2026-05-06T20:05:22Z` | canary | 0.00 | 5 | 0.000% | slow |
| `2026-05-06T20:05:27Z` | canary | 0.20 | 5 | 0.000% | slow |
| `2026-05-06T20:05:32Z` | canary | 0.00 | 5 | 0.000% | slow |
