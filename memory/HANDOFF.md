Last active: 2026-05-01 03:00 Asia/Shanghai
Current topic: daily symlink/security cron found unresolved broken symlinks.
Issue: 3 broken symlinks persist after `/root/.openclaw/workspace-chief/setup-symlinks.sh`.
Broken: `chief-user/FEEDBACK_PROTOCOL.md`, `market/OPPORTUNITY_DISCOVERY.md`, `market/SIGNAL_SCAN_CONFIG.md`.
Cause: chief root source files missing; OPPORTUNITY/SIGNAL versions only exist in `workspace-chief/archive/`.
CTX sync: benben/kefu/mangba/mangba-guest already in sync with main CTX-CONTROL-RULES.md.
Security audit: no rogue remotes; benben/kefu docker.network=`none`; sandbox images match latest `8ef0febba319`.
Next: decide whether to restore/create source files or remove obsolete symlinks/setup references.
Today note: memory/2026-05-01.md
