const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DATA_DIR = path.join(__dirname, '../../data');
const USERS_FILE = path.join(DATA_DIR, 'users.json');

function ensureStore() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }

  if (!fs.existsSync(USERS_FILE)) {
    fs.writeFileSync(USERS_FILE, JSON.stringify([]));
  }
}

function readUsers() {
  ensureStore();
  const raw = fs.readFileSync(USERS_FILE, 'utf8');
  return JSON.parse(raw);
}

function writeUsers(users) {
  ensureStore();
  fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
}

function findByEmail(email) {
  const users = readUsers();
  return users.find((user) => user.email === email.toLowerCase());
}

function createUser({ fullName, email, passwordHash }) {
  const users = readUsers();

  if (findByEmail(email)) {
    return null;
  }

  const user = {
    id: crypto.randomUUID(),
    fullName: fullName.trim(),
    email: email.trim().toLowerCase(),
    passwordHash,
    createdAt: new Date().toISOString(),
  };

  users.push(user);
  writeUsers(users);

  return user;
}

function toPublicUser(user) {
  return {
    id: user.id,
    fullName: user.fullName,
    email: user.email,
    createdAt: user.createdAt,
  };
}

module.exports = {
  findByEmail,
  createUser,
  toPublicUser,
};
