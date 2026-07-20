# Changelog

## 6.2.10.17-ha1 2026-07-20

- Added `java_max_heap_size`, `java_min_heap_size`, and `mongodb_wiredtiger_cache_size_gb`
  configuration options to help with OOM crash loops on memory-constrained hosts. All three are
  unset by default, so existing installs see no behavior change on upgrade. Setting
  `mongodb_wiredtiger_cache_size_gb` (e.g. `0.25`) is the most effective option if you're hitting
  OOM kills, since MongoDB's WiredTiger cache otherwise grows to ~50% of system RAM. See the main
  README's "Memory Tuning" section.
  Omada is still at 6.2.10.17; only the add-on configuration changed.

## 6.2.10.17

- Initial release of the HA OS variant.
- Uses MongoDB 7.0 (Ubuntu 22.04 base) to avoid tcmalloc `MmapAligned()` failures
  that occur when running MongoDB 8.0 inside HA OS containers on ARM64 hardware (e.g. Raspberry Pi 5).
