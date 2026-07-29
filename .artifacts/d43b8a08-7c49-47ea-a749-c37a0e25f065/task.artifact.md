# Audit & Debugging Task List

- [ ] **Infrastructure & Data Layer Audit**
    - [ ] Bible Repository: Audit custom ZIP extraction logic.
    - [ ] Database: Verify migration reliability and `ATTACH DATABASE` usage.
    - [ ] Sync Service: Check for potential data loss in `flushPendingQueue`.
    - [ ] Local Storage: Review key-value pairs and consistency.

- [ ] **Feature-Specific Audit**
    - [ ] Auth: Test edge cases for anonymous linking.
    - [ ] Bible Reader: Evaluate TTS lifecycle and scroll performance.
    - [ ] Global Search: Benchmark search speed and memory usage.
    - [ ] Weather: Audit permission handling and background updates.
    - [ ] Notifications: Verify reminder scheduling.

- [ ] **UI/UX & Performance**
    - [ ] Asset Audit: Check memory usage of 3D icons.
    - [ ] Theme Audit: Verify Material 3 color scheme compliance.
    - [ ] State Management: Optimize Riverpod provider usage.
