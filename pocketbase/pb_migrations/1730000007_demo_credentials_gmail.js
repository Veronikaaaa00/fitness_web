/// <reference path="../pb_data/types.d.ts" />
/**
 * Демо-логины: gmail + простые пароли (для уже поднятой БД).
 */
migrate((app) => {
  const usersCol = app.findCollectionByNameOrId("users");

  function upsertUser(email, password, name, role) {
    try {
      const rec = app.findAuthRecordByEmail("users", email);
      rec.set("role", role);
      rec.set("name", name);
      rec.set("password", password);
      rec.set("passwordConfirm", password);
      app.save(rec);
      return rec;
    } catch (_) {
      const rec = new Record(usersCol);
      rec.set("email", email);
      rec.set("password", password);
      rec.set("passwordConfirm", password);
      rec.set("name", name);
      rec.set("role", role);
      rec.set("emailVisibility", true);
      app.save(rec);
      return rec;
    }
  }

  upsertUser("admin@gmail.com", "admin123", "Админ Клуба", "admin");
  upsertUser("trainer@gmail.com", "trainer123", "Ирина Тренер", "trainer");
  upsertUser("member@gmail.com", "member123", "Клиент Тестов", "member");
  upsertUser("trainer2@gmail.com", "trainer123", "Павел Силов", "trainer");
  upsertUser("member2@gmail.com", "member123", "Анна Клиентова", "member");
  upsertUser("member3@gmail.com", "member123", "Олег Спортивный", "member");
}, (app) => {});
