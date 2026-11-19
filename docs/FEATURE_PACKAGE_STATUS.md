# Game-001 expanded development package

The following work is in the **development branch**, not a production release.

- Deterministic daily and weekly mission rules and rolling counters.
- Standalone local mission ledger and tests.
- Separate integrated Flutter source bundle is available in the current conversation, containing Time Attack, mission reward-claim UI, saved mission counters and original images.
- This branch's original game motor, 50,000 level descriptor metadata and monetization anti-abuse logic are not sufficient proof of full gameplay or real store billing.

## Release blockers
- All Flutter analyze/unit/widget/integration/device tests must pass.
- Time Attack, mission rewards and UI features in the local ZIP still need code integration into this GitHub branch.
- Store-signed IAP verification, live ads, crash reporting, device-specific screenshots, signed AAB/IPA and store policy acceptance are missing.
- No release should be marked complete until these gates have evidence.
