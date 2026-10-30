/// <reference path="../pb_data/types.d.ts" />
/**
 * Схема фитнес-клуба: поля users.role + базовые коллекции.
 */
migrate((app) => {
  // --- users: роль ---
  const users = app.findCollectionByNameOrId("users");
  users.listRule = '@request.auth.id != ""';
  users.viewRule = 'id = @request.auth.id || @request.auth.role = "admin"';
  users.createRule = "";
  users.updateRule = 'id = @request.auth.id || @request.auth.role = "admin"';
  users.deleteRule = '@request.auth.role = "admin"';

  // name уже есть в шаблоне; добавляем role если нет
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
  }
  app.save(users);

  const authed = '@request.auth.id != ""';
  const adminOnly = '@request.auth.role = "admin"';
  const staff = '@request.auth.role = "admin" || @request.auth.role = "trainer"';

  // --- rooms ---
  const rooms = new Collection({
    type: "base",
    name: "rooms",
    listRule: authed,
    viewRule: authed,
    createRule: adminOnly,
    updateRule: adminOnly,
    deleteRule: adminOnly,
    fields: [
      { name: "name", type: "text", required: true },
      { name: "capacity", type: "number", required: true, min: 1 },
      { name: "description", type: "text" },
      { name: "deleted", type: "bool" },
    ],
  });
  app.save(rooms);

  // --- trainers ---
  const trainers = new Collection({
    type: "base",
    name: "trainers",
    listRule: authed,
    viewRule: authed,
    createRule: adminOnly,
    updateRule: adminOnly,
    deleteRule: adminOnly,
    fields: [
      {
        name: "user",
        type: "relation",
        required: true,
        maxSelect: 1,
        collectionId: users.id,
        cascadeDelete: false,
      },
      { name: "fullName", type: "text", required: true },
      { name: "bio", type: "text" },
      { name: "deleted", type: "bool" },
    ],
  });
  app.save(trainers);

  // --- activity_types ---
  const activityTypes = new Collection({
    type: "base",
    name: "activity_types",
    listRule: authed,
    viewRule: authed,
    createRule: adminOnly,
    updateRule: adminOnly,
    deleteRule: adminOnly,
    fields: [
      { name: "name", type: "text", required: true },
      { name: "description", type: "text" },
      { name: "deleted", type: "bool" },
    ],
  });
  app.save(activityTypes);

  // --- membership_plans ---
  const plans = new Collection({
    type: "base",
    name: "membership_plans",
    listRule: authed,
    viewRule: authed,
    createRule: adminOnly,
    updateRule: adminOnly,
    deleteRule: adminOnly,
    fields: [
      { name: "title", type: "text", required: true },
      { name: "durationDays", type: "number", required: true, min: 1 },
      { name: "price", type: "number", required: true, min: 0 },
      { name: "description", type: "text" },
      { name: "visitsLimit", type: "number" },
      { name: "deleted", type: "bool" },
    ],
  });
  app.save(plans);

  // --- member_profiles (1:1) ---
  const profiles = new Collection({
    type: "base",
    name: "member_profiles",
    listRule: 'user = @request.auth.id || @request.auth.role = "admin"',
    viewRule: 'user = @request.auth.id || @request.auth.role = "admin"',
    createRule: 'user = @request.auth.id || @request.auth.role = "admin"',
    updateRule: 'user = @request.auth.id || @request.auth.role = "admin"',
    deleteRule: adminOnly,
    fields: [
      {
        name: "user",
        type: "relation",
        required: true,
        maxSelect: 1,
        collectionId: users.id,
        cascadeDelete: true,
      },
      { name: "phone", type: "text" },
      { name: "birthDate", type: "date" },
      { name: "notes", type: "text" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_member_profiles_user ON member_profiles (user)",
    ],
  });
  app.save(profiles);

  // --- memberships ---
  const memberships = new Collection({
    type: "base",
    name: "memberships",
    listRule:
      'member = @request.auth.id || @request.auth.role = "admin" || @request.auth.role = "trainer"',
    viewRule:
      'member = @request.auth.id || @request.auth.role = "admin" || @request.auth.role = "trainer"',
    createRule: adminOnly,
    updateRule: adminOnly,
    deleteRule: adminOnly,
    fields: [
      {
        name: "member",
        type: "relation",
        required: true,
        maxSelect: 1,
        collectionId: users.id,
      },
      {
        name: "plan",
        type: "relation",
        required: true,
        maxSelect: 1,
        collectionId: plans.id,
      },
      { name: "startsAt", type: "date", required: true },
      { name: "endsAt", type: "date", required: true },
      {
        name: "status",
        type: "select",
        required: true,
        maxSelect: 1,
        values: ["active", "expired", "cancelled"],
      },
      { name: "deleted", type: "bool" },
    ],
  });
  app.save(memberships);

  // --- equipment ---
  const equipment = new Collection({
    type: "base",
    name: "equipment",
    listRule: authed,
    viewRule: authed,
    createRule: adminOnly,
    updateRule: adminOnly,
    deleteRule: adminOnly,
    fields: [
      { name: "name", type: "text", required: true },
      { name: "quantity", type: "number", min: 0 },
      { name: "deleted", type: "bool" },
    ],
  });
  app.save(equipment);

  // --- classes ---
  const classes = new Collection({
    type: "base",
    name: "classes",
    listRule: authed,
    viewRule: authed,
    createRule: staff,
    updateRule: staff,
    deleteRule: adminOnly,
    fields: [
      { name: "title", type: "text", required: true },
      { name: "startsAt", type: "date", required: true },
      { name: "endsAt", type: "date", required: true },
      { name: "capacity", type: "number", required: true, min: 1 },
      { name: "bookedCount", type: "number", min: 0 },
      {
        name: "room",
        type: "relation",
        maxSelect: 1,
        collectionId: rooms.id,
      },
      {
        name: "trainer",
        type: "relation",
        maxSelect: 1,
        collectionId: trainers.id,
      },
      {
        name: "activityType",
        type: "relation",
        maxSelect: 1,
        collectionId: activityTypes.id,
      },
      { name: "cancelled", type: "bool" },
      { name: "deleted", type: "bool" },
    ],
  });
  app.save(classes);

  // --- bookings ---
  const bookings = new Collection({
    type: "base",
    name: "bookings",
    listRule:
      'member = @request.auth.id || @request.auth.role = "admin" || @request.auth.role = "trainer"',
    viewRule:
      'member = @request.auth.id || @request.auth.role = "admin" || @request.auth.role = "trainer"',
    createRule:
      '(@request.auth.id != "" && member = @request.auth.id) || @request.auth.role = "admin"',
    updateRule:
      'member = @request.auth.id || @request.auth.role = "admin"',
    deleteRule: adminOnly,
    fields: [
      {
        name: "member",
        type: "relation",
        required: true,
        maxSelect: 1,
        collectionId: users.id,
      },
      {
        name: "fitnessClass",
        type: "relation",
        required: true,
        maxSelect: 1,
        collectionId: classes.id,
      },
      {
        name: "status",
        type: "select",
        required: true,
        maxSelect: 1,
        values: ["confirmed", "cancelled", "attended", "noShow"],
      },
      { name: "deleted", type: "bool" },
    ],
  });
  app.save(bookings);

  // --- class_equipment (M:N) ---
  const classEquipment = new Collection({
    type: "base",
    name: "class_equipment",
    listRule: authed,
    viewRule: authed,
    createRule: staff,
    updateRule: staff,
    deleteRule: adminOnly,
    fields: [
      {
        name: "fitnessClass",
        type: "relation",
        required: true,
        maxSelect: 1,
        collectionId: classes.id,
        cascadeDelete: true,
      },
      {
        name: "equipment",
        type: "relation",
        required: true,
        maxSelect: 1,
        collectionId: equipment.id,
      },
      { name: "qty", type: "number", min: 1 },
    ],
  });
  app.save(classEquipment);
}, (app) => {
  const names = [
    "class_equipment",
    "bookings",
    "classes",
    "equipment",
    "memberships",
    "member_profiles",
    "membership_plans",
    "activity_types",
    "trainers",
    "rooms",
  ];
  for (const name of names) {
    try {
      app.delete(app.findCollectionByNameOrId(name));
    } catch (_) {}
  }
});
