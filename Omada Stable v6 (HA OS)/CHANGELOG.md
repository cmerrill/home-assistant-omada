# Changelog

## 6.2.10.17-ha1 2026-07-20

- Added `java_max_heap_size`, `java_min_heap_size`, and `mongodb_wiredtiger_cache_size_gb`
  configuration options to fix OOM crash loops on memory-constrained hosts. MongoDB's WiredTiger
  cache is now capped at 0.25 GB by default. See the main README's "Memory Tuning" section.
  Omada is still at 6.2.10.17; only the add-on configuration changed.

## 6.2.10.17

- Initial release of the HA OS variant.
- Uses MongoDB 7.0 (Ubuntu 22.04 base) to avoid tcmalloc `MmapAligned()` failures
  that occur when running MongoDB 8.0 inside HA OS containers on ARM64 hardware (e.g. Raspberry Pi 5).
