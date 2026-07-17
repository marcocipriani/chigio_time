'use strict';

const DELETE_FIELD = Symbol('delete-field');

class FakeTimestamp {
  constructor(milliseconds) {
    this.milliseconds = milliseconds;
  }

  toMillis() {
    return this.milliseconds;
  }
}

function clone(value) {
  if (value instanceof FakeTimestamp || value === DELETE_FIELD) return value;
  if (Array.isArray(value)) return value.map(clone);
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, nested]) => [key, clone(nested)]),
    );
  }
  return value;
}

function getField(data, fieldPath) {
  return fieldPath.split('.').reduce((value, segment) => value?.[segment], data);
}

function applyFields(target, fields) {
  for (const [fieldPath, rawValue] of Object.entries(fields)) {
    const segments = fieldPath.split('.');
    const leaf = segments.pop();
    let owner = target;
    for (const segment of segments) {
      if (!owner[segment] || typeof owner[segment] !== 'object') {
        owner[segment] = {};
      }
      owner = owner[segment];
    }
    if (rawValue === DELETE_FIELD) delete owner[leaf];
    else owner[leaf] = clone(rawValue);
  }
}

class FakeDocumentSnapshot {
  constructor(ref, record) {
    this.ref = ref;
    this.id = ref.id;
    this.exists = record !== undefined;
    this.createTime = record?.createTime;
    this._data = record?.data;
  }

  data() {
    return this.exists ? clone(this._data) : undefined;
  }
}

class FakeDocumentReference {
  constructor(db, path) {
    this.db = db;
    this.path = path;
    this.id = path.split('/').at(-1);
  }

  get parent() {
    return new FakeCollectionReference(
      this.db,
      this.path.split('/').slice(0, -1).join('/'),
    );
  }

  async get() {
    return this.db._snapshot(this.path);
  }

  async set(data, options = {}) {
    this.db._set(this.path, data, options);
  }

  async update(data) {
    this.db._update(this.path, data);
  }

  async create(data) {
    this.db._create(this.path, data);
  }

  async delete() {
    this.db.records.delete(this.path);
  }
}

class FakeQuery {
  constructor(db, source, filters = [], limitCount = null) {
    this.db = db;
    this.source = source;
    this.filters = filters;
    this.limitCount = limitCount;
  }

  where(field, operator, value) {
    return new FakeQuery(
      this.db,
      this.source,
      [...this.filters, { field, operator, value }],
      this.limitCount,
    );
  }

  limit(count) {
    return new FakeQuery(this.db, this.source, this.filters, count);
  }

  select() {
    return this;
  }

  async get() {
    let paths = [...this.db.records.keys()].filter((path) => {
      const segments = path.split('/');
      if (this.source.kind === 'collection') {
        const prefix = this.source.path ? `${this.source.path}/` : '';
        return path.startsWith(prefix) &&
          segments.length === this.source.path.split('/').length + 1;
      }
      return segments.at(-2) === this.source.name;
    });
    paths.sort();
    let docs = paths.map((path) => this.db._snapshot(path));
    docs = docs.filter((doc) => this.filters.every((filter) => {
      const actual = filter.field === '__name__'
        ? doc.id
        : getField(doc.data(), filter.field);
      const left = actual?.toMillis ? actual.toMillis() : actual;
      const right = filter.value?.toMillis
        ? filter.value.toMillis()
        : filter.value;
      if (filter.operator === '==') return left === right;
      if (filter.operator === '<=') return left <= right;
      if (filter.operator === '>=') return left >= right;
      throw new Error(`Unsupported operator ${filter.operator}`);
    }));
    if (this.limitCount !== null) docs = docs.slice(0, this.limitCount);
    return { docs, empty: docs.length === 0, size: docs.length };
  }
}

class FakeCollectionReference extends FakeQuery {
  constructor(db, path) {
    super(db, { kind: 'collection', path });
    this.path = path;
    this.id = path.split('/').at(-1);
  }

  get parent() {
    const segments = this.path.split('/');
    if (segments.length < 2) return null;
    return new FakeDocumentReference(
      this.db,
      segments.slice(0, -1).join('/'),
    );
  }
}

class FakeTransaction {
  constructor(db) {
    this.db = db;
    this.operations = [];
    this.hasWritten = false;
  }

  async get(ref) {
    if (this.hasWritten) throw new Error('Transaction read after write');
    return ref.get();
  }

  update(ref, data) {
    this.hasWritten = true;
    this.operations.push(() => this.db._update(ref.path, data));
  }

  create(ref, data) {
    this.hasWritten = true;
    this.operations.push(() => this.db._create(ref.path, data));
  }

  commit() {
    for (const operation of this.operations) operation();
  }
}

class FakeFirestore {
  constructor(nowMs = Date.parse('2026-07-17T08:00:00+02:00')) {
    this.nowMs = nowMs;
    this.records = new Map();
  }

  seed(path, data, { createTimeMs = this.nowMs } = {}) {
    this.records.set(path, {
      data: clone(data),
      createTime: new FakeTimestamp(createTimeMs),
    });
  }

  data(path) {
    return this._snapshot(path).data();
  }

  doc(path) {
    return new FakeDocumentReference(this, path);
  }

  collection(path) {
    return new FakeCollectionReference(this, path);
  }

  collectionGroup(name) {
    return new FakeQuery(this, { kind: 'collectionGroup', name });
  }

  async getAll(...refs) {
    if (!(refs.at(-1) instanceof FakeDocumentReference)) refs.pop();
    return Promise.all(refs.map((ref) => ref.get()));
  }

  async runTransaction(callback) {
    const transaction = new FakeTransaction(this);
    const result = await callback(transaction);
    transaction.commit();
    return result;
  }

  _snapshot(path) {
    return new FakeDocumentSnapshot(this.doc(path), this.records.get(path));
  }

  _set(path, data, { merge = false } = {}) {
    const existing = this.records.get(path);
    const next = merge && existing ? clone(existing.data) : {};
    applyFields(next, data);
    this.records.set(path, {
      data: next,
      createTime: existing?.createTime ?? new FakeTimestamp(this.nowMs),
    });
  }

  _update(path, data) {
    const existing = this.records.get(path);
    if (!existing) throw Object.assign(new Error('not-found'), { code: 5 });
    const next = clone(existing.data);
    applyFields(next, data);
    this.records.set(path, { ...existing, data: next });
  }

  _create(path, data) {
    if (this.records.has(path)) {
      throw Object.assign(new Error('already-exists'), { code: 6 });
    }
    this.seed(path, data);
  }
}

class FakeMessaging {
  constructor(responses = []) {
    this.responses = [...responses];
    this.calls = [];
  }

  async sendEachForMulticast(payload) {
    this.calls.push(clone(payload));
    const response = this.responses.shift();
    if (typeof response === 'function') return response(payload);
    if (response instanceof Error) throw response;
    if (!response) throw new Error('Missing fake messaging response');
    return clone(response);
  }
}

class FakeLogger {
  constructor() {
    this.infoLines = [];
    this.errorLines = [];
  }

  info(line) {
    this.infoLines.push(line);
  }

  error(line) {
    this.errorLines.push(line);
  }
}

module.exports = {
  DELETE_FIELD,
  FakeFirestore,
  FakeLogger,
  FakeMessaging,
  FakeTimestamp,
};
