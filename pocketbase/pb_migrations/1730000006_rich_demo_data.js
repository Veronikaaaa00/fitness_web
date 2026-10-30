/// <reference path="../pb_data/types.d.ts" />
/**
 * Дополнительные демо-данные: клиенты, залы, занятия, записи, инвентарь.
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

  const admin = upsertUser("admin@gmail.com", "admin123", "Админ Клуба", "admin");
  const trainerUser = upsertUser("trainer@gmail.com", "trainer123", "Ирина Тренер", "trainer");
  const trainer2User = upsertUser("trainer2@gmail.com", "trainer123", "Павел Силов", "trainer");
  const member = upsertUser("member@gmail.com", "member123", "Клиент Тестов", "member");
  const member2 = upsertUser("member2@gmail.com", "member123", "Анна Клиентова", "member");
  const member3 = upsertUser("member3@gmail.com", "member123", "Олег Спортивный", "member");

  const roomsCol = app.findCollectionByNameOrId("rooms");
  function ensureRoom(name, capacity, description) {
    const found = app.findRecordsByFilter(roomsCol, `name="${name}"`, "", 1, 0);
    if (found.length) return found[0];
    const r = new Record(roomsCol);
    r.set("name", name);
    r.set("capacity", capacity);
    r.set("description", description);
    r.set("deleted", false);
    app.save(r);
    return r;
  }
  const roomA = ensureRoom("Зал А", 20, "Основной зал");
  const roomB = ensureRoom("Зал B", 12, "Малый зал");
  const roomC = ensureRoom("Зал C", 8, "Студия");

  const trainersCol = app.findCollectionByNameOrId("trainers");
  function ensureTrainer(user, fullName, bio) {
    const found = app.findRecordsByFilter(trainersCol, `user="${user.id}"`, "", 1, 0);
    if (found.length) return found[0];
    const t = new Record(trainersCol);
    t.set("user", user.id);
    t.set("fullName", fullName);
    t.set("bio", bio);
    t.set("deleted", false);
    app.save(t);
    return t;
  }
  const trainer1 = ensureTrainer(trainerUser, "Ирина Тренер", "Йога и пилатес");
  const trainer2 = ensureTrainer(trainer2User, "Павел Силов", "Силовые и функционал");

  const typesCol = app.findCollectionByNameOrId("activity_types");
  function ensureType(name, description) {
    const found = app.findRecordsByFilter(typesCol, `name="${name}"`, "", 1, 0);
    if (found.length) return found[0];
    const t = new Record(typesCol);
    t.set("name", name);
    t.set("description", description);
    t.set("deleted", false);
    app.save(t);
    return t;
  }
  const yoga = ensureType("Йога", "Хатха-йога");
  const strength = ensureType("Силовая", "Функциональный тренинг");
  const pilates = ensureType("Пилатес", "Кор и гибкость");
  const cardio = ensureType("Кардио", "Интервальные нагрузки");

  const plansCol = app.findCollectionByNameOrId("membership_plans");
  function ensurePlan(title, days, price, visitsLimit) {
    const found = app.findRecordsByFilter(plansCol, `title="${title}"`, "", 1, 0);
    if (found.length) return found[0];
    const p = new Record(plansCol);
    p.set("title", title);
    p.set("durationDays", days);
    p.set("price", price);
    p.set("description", title);
    if (visitsLimit) p.set("visitsLimit", visitsLimit);
    p.set("deleted", false);
    app.save(p);
    return p;
  }
  const planMonth = ensurePlan("Месяц безлимит", 30, 3000);
  const planOnce = ensurePlan("Разовый", 1, 500, 1);
  const planYear = ensurePlan("Год VIP", 365, 28000);

  const profilesCol = app.findCollectionByNameOrId("member_profiles");
  function ensureProfile(user, phone) {
    const found = app.findRecordsByFilter(profilesCol, `user="${user.id}"`, "", 1, 0);
    if (found.length) return found[0];
    const p = new Record(profilesCol);
    p.set("user", user.id);
    p.set("phone", phone);
    app.save(p);
    return p;
  }
  ensureProfile(member, "+79001234567");
  ensureProfile(member2, "+79007654321");
  ensureProfile(member3, "+79005551212");

  const membershipsCol = app.findCollectionByNameOrId("memberships");
  function ensureMembership(user, plan) {
    const found = app.findRecordsByFilter(
      membershipsCol,
      `member="${user.id}" && status="active"`,
      "",
      1,
      0,
    );
    if (found.length) return found[0];
    const now = new Date();
    const ends = new Date(now.getTime() + plan.get("durationDays") * 24 * 60 * 60 * 1000);
    const m = new Record(membershipsCol);
    m.set("member", user.id);
    m.set("plan", plan.id);
    m.set("startsAt", now.toISOString());
    m.set("endsAt", ends.toISOString());
    m.set("status", "active");
    m.set("deleted", false);
    app.save(m);
    return m;
  }
  ensureMembership(member, planMonth);
  ensureMembership(member2, planMonth);
  ensureMembership(member3, planYear);
  ensureMembership(admin, planMonth);

  const equipmentCol = app.findCollectionByNameOrId("equipment");
  function ensureEquipment(name, qty) {
    const found = app.findRecordsByFilter(equipmentCol, `name="${name}"`, "", 1, 0);
    if (found.length) return found[0];
    const e = new Record(equipmentCol);
    e.set("name", name);
    e.set("quantity", qty);
    e.set("deleted", false);
    app.save(e);
    return e;
  }
  const mats = ensureEquipment("Коврик", 30);
  const dumbbells = ensureEquipment("Гантели", 40);
  const bands = ensureEquipment("Резинки", 25);

  const classesCol = app.findCollectionByNameOrId("classes");
  const classEquipCol = app.findCollectionByNameOrId("class_equipment");
  const bookingsCol = app.findCollectionByNameOrId("bookings");

  function addClass(title, dayOffset, hour, capacity, room, trainer, activity, equip, equipQty) {
    const start = new Date();
    start.setDate(start.getDate() + dayOffset);
    start.setHours(hour, 0, 0, 0);
    const end = new Date(start.getTime() + 60 * 60 * 1000);

    const existing = app.findRecordsByFilter(
      classesCol,
      `title="${title}" && startsAt="${start.toISOString()}"`,
      "",
      1,
      0,
    );
    let c;
    if (existing.length) {
      c = existing[0];
    } else {
      c = new Record(classesCol);
      c.set("title", title);
      c.set("startsAt", start.toISOString());
      c.set("endsAt", end.toISOString());
      c.set("capacity", capacity);
      c.set("bookedCount", 0);
      c.set("room", room.id);
      c.set("trainer", trainer.id);
      c.set("activityType", activity.id);
      c.set("cancelled", false);
      c.set("deleted", false);
      app.save(c);

      if (equip) {
        const link = new Record(classEquipCol);
        link.set("fitnessClass", c.id);
        link.set("equipment", equip.id);
        link.set("qty", equipQty || 10);
        app.save(link);
      }
    }
    return c;
  }

  const schedule = [
    addClass("Утренняя йога", 1, 9, 15, roomA, trainer1, yoga, mats, 15),
    addClass("Силовая группа", 1, 18, 12, roomB, trainer2, strength, dumbbells, 12),
    addClass("Вечерняя йога", 2, 19, 15, roomA, trainer1, yoga, mats, 15),
    addClass("Пилатес утро", 2, 10, 10, roomC, trainer1, pilates, bands, 10),
    addClass("Кардио HIIT", 3, 17, 16, roomB, trainer2, cardio, bands, 16),
    addClass("Силовой круг", 3, 19, 12, roomA, trainer2, strength, dumbbells, 12),
    addClass("Йога выходного", 5, 11, 18, roomA, trainer1, yoga, mats, 18),
    addClass("Функционал", 4, 12, 10, roomC, trainer2, strength, bands, 10),
  ];

  function ensureBooking(user, fitnessClass) {
    const found = app.findRecordsByFilter(
      bookingsCol,
      `member="${user.id}" && fitnessClass="${fitnessClass.id}" && status="confirmed"`,
      "",
      1,
      0,
    );
    if (found.length) return found[0];
    const b = new Record(bookingsCol);
    b.set("member", user.id);
    b.set("fitnessClass", fitnessClass.id);
    b.set("status", "confirmed");
    b.set("deleted", false);
    app.save(b);
    const count = Number(fitnessClass.get("bookedCount") || 0) + 1;
    fitnessClass.set("bookedCount", count);
    app.save(fitnessClass);
    return b;
  }

  // Одна демо-запись у клиента — чтобы можно было спокойно записаться на другие слоты.
  ensureBooking(member, schedule[0]);
  ensureBooking(member2, schedule[0]);
  ensureBooking(member3, schedule[1]);
  ensureBooking(member2, schedule[3]);
  ensureBooking(admin, schedule[4]);

  void planOnce;
}, (app) => {});
