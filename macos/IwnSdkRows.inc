        // In-World Navigation. Mac RVAs for hashes this plugin names. Format: { hash, RVA },  // name.
        { 1661347149, 0x24e6b34 },  // UpdateNavPath. void(this). Hooked. Calls UpdateFromPoints for quest then POI.
        { 3770693656, 0x24e6714 },  // UpdateGPSPath thunk. Real entry, no callers. Not hooked.
