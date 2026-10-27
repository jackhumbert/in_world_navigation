        // In-World Navigation. Mac RVAs for hashes this plugin names. Format: { hash, RVA },  // name.
        { 1661347149, 0x4c55228 },  // UpdateNavPath. void(this). Hooked. Calls UpdateFromPoints for quest then POI.
        { 3770693656, 0x4c54e44 },  // UpdateGPSPath thunk. Real entry, no callers. Not hooked.
