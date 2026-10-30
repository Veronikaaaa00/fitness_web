/// <reference path="../pb_data/types.d.ts" />
/** Абонемент админу, чтобы можно было тестировать запись на занятие. */
migrate((app) => {
  let admin;
  try {
    admin = app.findAuthRecordByEmail("users", "admin@gmail.com");
  } catch (_) {
    return;
  }

  const plans = app.findCollectionByNameOrId("membership_plans");
  const planRows = app.findRecordsByFilter(plans, "deleted=false", "-id", 1, 0);
  if (!planRows.length) return;
  const plan = planRows[0];

  const memberships = app.findCollectionByNameOrId("memberships");
  const existing = app.findRecordsByFilter(
    memberships,
    `member="${admin.id}" && status="active"`,
    "",
    1,
    0,
  );
  if (existing.length) return;

  const now = new Date();
  const ends = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  const m = new Record(memberships);
  m.set("member", admin.id);
  m.set("plan", plan.id);
  m.set("startsAt", now.toISOString());
  m.set("endsAt", ends.toISOString());
  m.set("status", "active");
  m.set("deleted", false);
  app.save(m);
}, (app) => {});
