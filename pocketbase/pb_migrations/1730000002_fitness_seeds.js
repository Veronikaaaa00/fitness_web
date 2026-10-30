/// <reference path="../pb_data/types.d.ts" />
/**
 * Демо-данные: 3 роли, зал, тип, тариф, абонемент, занятия.
 */
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");

  function upsertUser(email, password, name, role) {
    try {
      return app.findAuthRecordByEmail("users", email);
    } catch (_) {
      const rec = new Record(users);
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

  const admin = upsertUser(
    "admin@gmail.com",
    "admin123",
    "Админ Клуба",
    "admin",
  );
  const trainerUser = upsertUser(
    "trainer@gmail.com",
    "trainer123",
    "Ирина Тренер",
    "trainer",
  );
  const member = upsertUser(
    "member@gmail.com",
    "member123",
    "Клиент Тестов",
    "member",
  );

  const rooms = app.findCollectionByNameOrId("rooms");
  const room = new Record(rooms);
  room.set("name", "Зал А");
  room.set("capacity", 20);
  room.set("description", "Основной зал");
  room.set("deleted", false);
  app.save(room);

  const roomB = new Record(rooms);
  roomB.set("name", "Зал B");
  roomB.set("capacity", 12);
  roomB.set("description", "Малый зал");
  roomB.set("deleted", false);
  app.save(roomB);

  const trainers = app.findCollectionByNameOrId("trainers");
  const trainer = new Record(trainers);
  trainer.set("user", trainerUser.id);
  trainer.set("fullName", "Ирина Тренер");
  trainer.set("bio", "Йога и пилатес");
  trainer.set("deleted", false);
  app.save(trainer);

  const activityTypes = app.findCollectionByNameOrId("activity_types");
  const yoga = new Record(activityTypes);
  yoga.set("name", "Йога");
  yoga.set("description", "Хатха-йога");
  yoga.set("deleted", false);
  app.save(yoga);

  const strength = new Record(activityTypes);
  strength.set("name", "Силовая");
  strength.set("description", "Функциональный тренинг");
  strength.set("deleted", false);
  app.save(strength);

  const plans = app.findCollectionByNameOrId("membership_plans");
  const plan = new Record(plans);
  plan.set("title", "Месяц безлимит");
  plan.set("durationDays", 30);
  plan.set("price", 3000);
  plan.set("description", "Все групповые занятия");
  plan.set("deleted", false);
  app.save(plan);

  const plan2 = new Record(plans);
  plan2.set("title", "Разовый");
  plan2.set("durationDays", 1);
  plan2.set("price", 500);
  plan2.set("visitsLimit", 1);
  plan2.set("deleted", false);
  app.save(plan2);

  const profiles = app.findCollectionByNameOrId("member_profiles");
  const profile = new Record(profiles);
  profile.set("user", member.id);
  profile.set("phone", "+79001234567");
  app.save(profile);

  const memberships = app.findCollectionByNameOrId("memberships");
  const now = new Date();
  const ends = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  const membership = new Record(memberships);
  membership.set("member", member.id);
  membership.set("plan", plan.id);
  membership.set("startsAt", now.toISOString());
  membership.set("endsAt", ends.toISOString());
  membership.set("status", "active");
  membership.set("deleted", false);
  app.save(membership);

  const equipmentCol = app.findCollectionByNameOrId("equipment");
  const mats = new Record(equipmentCol);
  mats.set("name", "Коврик");
  mats.set("quantity", 30);
  mats.set("deleted", false);
  app.save(mats);

  const classes = app.findCollectionByNameOrId("classes");
  function addClass(title, dayOffset, hour, capacity, roomId, activityId) {
    const start = new Date();
    start.setDate(start.getDate() + dayOffset);
    start.setHours(hour, 0, 0, 0);
    const end = new Date(start.getTime() + 60 * 60 * 1000);
    const c = new Record(classes);
    c.set("title", title);
    c.set("startsAt", start.toISOString());
    c.set("endsAt", end.toISOString());
    c.set("capacity", capacity);
    c.set("bookedCount", 0);
    c.set("room", roomId);
    c.set("trainer", trainer.id);
    c.set("activityType", activityId);
    c.set("cancelled", false);
    c.set("deleted", false);
    app.save(c);
    return c;
  }

  const c1 = addClass("Утренняя йога", 1, 9, 15, room.id, yoga.id);
  addClass("Силовая группа", 1, 18, 12, roomB.id, strength.id);
  addClass("Вечерняя йога", 2, 19, 15, room.id, yoga.id);

  const classEquipment = app.findCollectionByNameOrId("class_equipment");
  const link = new Record(classEquipment);
  link.set("fitnessClass", c1.id);
  link.set("equipment", mats.id);
  link.set("qty", 15);
  app.save(link);

  // silence unused
  void admin;
}, (app) => {
  // сиды не откатываем точечно — достаточно migrate down схемы
});
