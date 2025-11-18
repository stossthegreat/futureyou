<!-- ed7ec8fc-e517-4271-af50-875ee5c4828f f9855e0e-26d5-4112-878a-7b78b1769b20 -->
# Fix Critical UI and Backend Issues

Issues Found



1. Debrief Classification Bug







backend/src/modules/coach/coach.service.ts line 123: evening_debrief maps to "brief" instead of "debrief"



lib/services/messages_service.dart line 244: CoachMessageKind.mirror incorrectly maps to model.MessageKind.debrief



2. Nudge Duplication







Two scheduler files both setting up nudge jobs: backend/src/workers/scheduler.worker.ts and backend/src/jobs/scheduler.ts



3. Welcome Series Grey Screen







Async initialization issues in lib/screens/home_screen.dart



Null pointer exceptions in welcome series logic



4. AI Name Usage







AI falls back to "Friend" even when user provides name



Identity storage works but AI logic needs refinement



5. Brief Close Button







Parchment scroll dismiss not properly removing briefs from home screen



Implementation Steps

### To-dos

- [ ] Fix debrief classification in backend coach service and controller
- [ ] Fix API kind mapping in Flutter messages service
- [ ] Remove duplicate nudge scheduler to fix duplication
- [ ] Add error handling to welcome series to prevent grey screen
- [ ] Update AI service to properly use user-provided names
- [ ] Fix brief close button to properly dismiss from home screen
- [ ] Add interactive feedback sections to briefs and debriefs