/// <reference path="../pb_data/types.d.ts" />
/**
 * Переименовывает relation `class` → `fitnessClass` (class — плохое имя для PB)
 * и добавляет autodate created/updated, если их нет.
 */
migrate((app) => {
  function ensureAutodates(collection) {
    let hasCreated = false;
    let hasUpdated = false;
    collection.fields.forEach((f) => {
      if (f.name === "created") hasCreated = true;
      if (f.name === "updated") hasUpdated = true;
    });
    if (!hasCreated) {
      collection.fields.add(
        new Field({ name: "created", type: "autodate", onCreate: true, onUpdate: false }),
      );
    }
    if (!hasUpdated) {
      collection.fields.add(
        new Field({
          name: "updated",
          type: "autodate",
          onCreate: true,
          onUpdate: true,
        }),
      );
    }
  }

  function renameClassField(collectionName) {
    const col = app.findCollectionByNameOrId(collectionName);
    let field = null;
    col.fields.forEach((f) => {
      if (f.name === "class") field = f;
    });
    if (field) {
      field.name = "fitnessClass";
    }
    ensureAutodates(col);
    app.save(col);
  }

  renameClassField("bookings");
  renameClassField("class_equipment");

  // Правила записей: клиент только свои; staff видит всё; create только себе (или admin)
  const bookings = app.findCollectionByNameOrId("bookings");
  bookings.listRule =
    'member = @request.auth.id || @request.auth.role = "admin" || @request.auth.role = "trainer"';
  bookings.viewRule = bookings.listRule;
  bookings.createRule =
    '(@request.auth.id != "" && member = @request.auth.id) || @request.auth.role = "admin"';
  bookings.updateRule =
    'member = @request.auth.id || @request.auth.role = "admin"';
  bookings.deleteRule = '@request.auth.role = "admin"';
  app.save(bookings);
}, (app) => {
  const bookings = app.findCollectionByNameOrId("bookings");
  let field = null;
  bookings.fields.forEach((f) => {
    if (f.name === "fitnessClass") field = f;
  });
  if (field) field.name = "class";
  app.save(bookings);
});
