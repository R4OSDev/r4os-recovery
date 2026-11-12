# 0.79.43 targeted stability checks

2026-09-21; software/model evidence. Windows uses Build.bat with the same arguments.

```text
From the Libraries repository:
./Build.sh R4GFX test '-Dprovider-test-filter=layout overflow'
Existing provider group: two active outputs; resize rejected without changing
references/mappings; one output disappears while the other completes. Close
returns all provider objects, maps, queue handles and references to zero.
Command exited 0. No R4GFX artifact/ABI change.
```

Full software scope and physical exclusions: workspace Docs/Deployment/GrafikStabilitaet07943.txt.
