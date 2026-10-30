/// <reference path="../pb_data/types.d.ts" />
/**
 * Добавляет users.role (в первой миграции поле могло не сохраниться)
 * и проставляет роли демо-аккаунтам.
 */
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");

  let hasRole = false;
  users.fields.forEach((f) => {
    if (f.name === "role") hasRole = true;
  });

  if (!hasRole) {
    users.fields.add(
      new Field({
        name: "role",
        type: "select",
        required: true,
        maxSelect: 1,
        values: ["member", "trainer", "admin"],
      }),
    );
    app.save(users);
  }

  const map = {
    "admin@gmail.com": "admin",
    "trainer@gmail.com": "trainer",
    "member@gmail.com": "member",
  };

  for (const email in map) {
    try {
      const rec = app.findAuthRecordByEmail("users", email);
      rec.set("role", map[email]);
      app.save(rec);
    } catch (_) {}
  }
}, (app) => {
  // leave role field in place
});
