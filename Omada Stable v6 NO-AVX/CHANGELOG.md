# Changelog

## 6.1.0.19-ha1 2026-07-20

- Added `java_max_heap_size`, `java_min_heap_size`, and `mongodb_wiredtiger_cache_size_gb`
  configuration options to help with OOM crash loops on memory-constrained hosts. All three are
  unset by default, so existing installs see no behavior change on upgrade. Setting
  `mongodb_wiredtiger_cache_size_gb` (e.g. `0.25`) is the most effective option if you're hitting
  OOM kills, since MongoDB's WiredTiger cache otherwise grows to ~50% of system RAM. See the main
  README's "Memory Tuning" section.
  Omada is still at 6.1.0.19; only the add-on configuration changed.

## 6.0.0.23-noavx 2026-01-11

- Initial release of the No-AVX variant.
- Includes MongoDB compiled without AVX instructions to support older x86_64 CPUs.
- Based on Omada Controller v6.0.0.23.
