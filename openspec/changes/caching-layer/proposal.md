# Proposal: Caching Layer

## Why

Performance is critical for a mobile terminal app. Users expect instant response
when scrolling through blocks, searching history, or switching sessions. A
multi-layer caching strategy (memory -> Hive -> SQLite) ensures fast access to
frequently-used data while maintaining full persistence.

## What Changes

- Implement CacheManager with three-layer hierarchy
- L1: In-memory cache for active session data
- L2: Hive key-value store for recently accessed data
- L3: SQLite (Drift) for full persistence
- Define cache invalidation policies
- Implement cache warming on session switch
- Add cache statistics for debugging
- Configure cache size limits and eviction

## Capabilities

### New Capabilities

- `memory-cache`: In-memory LRU cache for active data
- `hive-cache`: Fast KV storage for recent data
- `cache-warming`: Pre-load data on session switch
- `cache-invalidation`: Coordinated cache updates
- `cache-stats`: Debug cache hit/miss rates

## Impact

- `lib/core/cache/cache_manager.dart`: Main cache coordinator
- `lib/core/cache/memory_cache.dart`: L1 in-memory cache
- `lib/core/cache/hive_cache.dart`: L2 Hive cache
- `lib/core/cache/cache_policy.dart`: Cache policies
- Modify DAOs to use cache manager

## Dependencies

- `block-persistence`: Cache blocks from SQLite
- `command-history`: Cache history for ribbon

## Phase

**Phase 1 - MVP** (Weeks 13-14 - Polish)

## Priority

**P1 - Should Have**

Performance optimization for smooth scrolling and instant search.
