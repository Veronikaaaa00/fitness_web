/// Разрешаем клиенту обновлять bookedCount при записи на занятие.
/// Иначе PATCH /classes/{id} для member даёт 404 и запись «ломается» в UI.
migrate(
  (app) => {
    const classes = app.findCollectionByNameOrId("classes");
    classes.updateRule =
      '@request.auth.role = "admin" || @request.auth.role = "trainer" || (@request.auth.id != "" && @request.body.bookedCount:isset = true)';
    app.save(classes);
  },
  (app) => {
    const classes = app.findCollectionByNameOrId("classes");
    classes.updateRule =
      '@request.auth.role = "admin" || @request.auth.role = "trainer"';
    app.save(classes);
  },
);
