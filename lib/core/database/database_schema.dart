abstract final class DatabaseSchema {
  static const databaseName = 'hasanah.db';
  static const version = 3;

  static const users = 'users';
  static const permissions = 'permissions';
  static const rolePermissions = 'role_permissions';
  static const circles = 'circles';
  static const circleStudents = 'circle_students';
  static const attendance = 'attendance';
  static const evaluations = 'evaluations';
  static const rewardStore = 'reward_store';
  static const walletTransactions = 'wallet_transactions';
  static const instituteEvents = 'institute_events';
  static const teachingSessions = 'teaching_sessions';
  static const pointLedger = 'point_ledger';
  static const qaQuestions = 'qa_questions';

  static const createStatements = <String>[
    '''
      CREATE TABLE $users (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('admin', 'teacher', 'student', 'parent')),
        parent_id TEXT REFERENCES $users(id) ON DELETE SET NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE $permissions (
        id TEXT PRIMARY KEY NOT NULL,
        code TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE $rolePermissions (
        role TEXT NOT NULL CHECK(role IN ('admin', 'teacher', 'student', 'parent')),
        permission_id TEXT NOT NULL REFERENCES $permissions(id) ON DELETE CASCADE,
        PRIMARY KEY (role, permission_id)
      )
    ''',
    '''
      CREATE TABLE $circles (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        teacher_id TEXT NOT NULL REFERENCES $users(id) ON DELETE RESTRICT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE $circleStudents (
        circle_id TEXT NOT NULL REFERENCES $circles(id) ON DELETE CASCADE,
        student_id TEXT NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
        created_at TEXT NOT NULL,
        PRIMARY KEY (circle_id, student_id)
      )
    ''',
    '''
      CREATE TABLE $teachingSessions (
        id TEXT PRIMARY KEY NOT NULL,
        circle_id TEXT NOT NULL REFERENCES $circles(id) ON DELETE CASCADE,
        teacher_id TEXT NOT NULL REFERENCES $users(id) ON DELETE RESTRICT,
        session_date TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        status TEXT NOT NULL CHECK(status IN ('open', 'closed')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(circle_id, session_date)
      )
    ''',
    '''
      CREATE TABLE $attendance (
        id TEXT PRIMARY KEY NOT NULL,
        student_id TEXT NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
        circle_id TEXT NOT NULL REFERENCES $circles(id) ON DELETE CASCADE,
        session_id TEXT REFERENCES $teachingSessions(id) ON DELETE SET NULL,
        attendance_date TEXT NOT NULL,
        attendance_at TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('present', 'absent', 'late')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(student_id, circle_id, attendance_date)
      )
    ''',
    '''
      CREATE TABLE $evaluations (
        id TEXT PRIMARY KEY NOT NULL,
        student_id TEXT NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
        circle_id TEXT REFERENCES $circles(id) ON DELETE SET NULL,
        evaluated_at TEXT NOT NULL,
        new_hifz_score REAL NOT NULL CHECK(new_hifz_score BETWEEN 0 AND 10),
        close_review_score REAL NOT NULL CHECK(close_review_score BETWEEN 0 AND 10),
        distant_review_score REAL NOT NULL CHECK(distant_review_score BETWEEN 0 AND 10),
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE $pointLedger (
        id TEXT PRIMARY KEY NOT NULL,
        student_id TEXT NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
        circle_id TEXT NOT NULL REFERENCES $circles(id) ON DELETE CASCADE,
        session_id TEXT REFERENCES $teachingSessions(id) ON DELETE SET NULL,
        points INTEGER NOT NULL CHECK(points > 0),
        reason TEXT NOT NULL CHECK(reason IN ('attendance', 'award', 'qa')),
        note TEXT,
        awarded_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE $qaQuestions (
        id TEXT PRIMARY KEY NOT NULL,
        circle_id TEXT NOT NULL REFERENCES $circles(id) ON DELETE CASCADE,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        created_by TEXT NOT NULL REFERENCES $users(id) ON DELETE RESTRICT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    'CREATE INDEX idx_users_parent_id ON $users(parent_id)',
    'CREATE INDEX idx_circles_teacher_id ON $circles(teacher_id)',
    'CREATE INDEX idx_circle_students_student_id ON $circleStudents(student_id)',
    'CREATE INDEX idx_attendance_student_date ON $attendance(student_id, attendance_date)',
    'CREATE INDEX idx_attendance_circle_date ON $attendance(circle_id, attendance_date)',
    'CREATE INDEX idx_evaluations_student_date ON $evaluations(student_id, evaluated_at)',
    'CREATE INDEX idx_evaluations_circle_date ON $evaluations(circle_id, evaluated_at)',
    'CREATE INDEX idx_sessions_circle_date ON $teachingSessions(circle_id, session_date)',
    'CREATE INDEX idx_point_ledger_circle_awarded ON $pointLedger(circle_id, awarded_at)',
    'CREATE INDEX idx_point_ledger_student ON $pointLedger(student_id, awarded_at)',
    'CREATE INDEX idx_qa_questions_circle ON $qaQuestions(circle_id)',
    '''
      CREATE TABLE $rewardStore (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        token_cost INTEGER NOT NULL CHECK(token_cost > 0),
        available_quantity INTEGER NOT NULL DEFAULT 0 CHECK(available_quantity >= 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE $walletTransactions (
        id TEXT PRIMARY KEY NOT NULL,
        student_id TEXT NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
        reward_id TEXT REFERENCES $rewardStore(id) ON DELETE SET NULL,
        amount INTEGER NOT NULL CHECK(amount != 0),
        transaction_type TEXT NOT NULL CHECK(
          transaction_type IN ('evaluation', 'redemption', 'adjustment')
        ),
        created_at TEXT NOT NULL
      )
    ''',
    'CREATE INDEX idx_wallet_transactions_student ON $walletTransactions(student_id, created_at)',
    '''
      CREATE TABLE $instituteEvents (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        event_type TEXT NOT NULL CHECK(event_type IN ('event', 'competition')),
        starts_at TEXT NOT NULL,
        ends_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    'CREATE INDEX idx_institute_events_starts_at ON $instituteEvents(starts_at)',
  ];

  static const migrationV2Statements = <String>[
    '''
      ALTER TABLE $evaluations
      ADD COLUMN circle_id TEXT REFERENCES $circles(id) ON DELETE SET NULL
    ''',
    'CREATE INDEX IF NOT EXISTS idx_evaluations_circle_date ON $evaluations(circle_id, evaluated_at)',
    '''
      CREATE TABLE IF NOT EXISTS $rewardStore (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        token_cost INTEGER NOT NULL CHECK(token_cost > 0),
        available_quantity INTEGER NOT NULL DEFAULT 0 CHECK(available_quantity >= 0),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS $walletTransactions (
        id TEXT PRIMARY KEY NOT NULL,
        student_id TEXT NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
        reward_id TEXT REFERENCES $rewardStore(id) ON DELETE SET NULL,
        amount INTEGER NOT NULL CHECK(amount != 0),
        transaction_type TEXT NOT NULL CHECK(
          transaction_type IN ('evaluation', 'redemption', 'adjustment')
        ),
        created_at TEXT NOT NULL
      )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_wallet_transactions_student ON $walletTransactions(student_id, created_at)',
    '''
      CREATE TABLE IF NOT EXISTS $instituteEvents (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        event_type TEXT NOT NULL CHECK(event_type IN ('event', 'competition')),
        starts_at TEXT NOT NULL,
        ends_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_institute_events_starts_at ON $instituteEvents(starts_at)',
  ];

  static const migrationV3Statements = <String>[
    '''
      CREATE TABLE IF NOT EXISTS $teachingSessions (
        id TEXT PRIMARY KEY NOT NULL,
        circle_id TEXT NOT NULL REFERENCES $circles(id) ON DELETE CASCADE,
        teacher_id TEXT NOT NULL REFERENCES $users(id) ON DELETE RESTRICT,
        session_date TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        status TEXT NOT NULL CHECK(status IN ('open', 'closed')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(circle_id, session_date)
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS $pointLedger (
        id TEXT PRIMARY KEY NOT NULL,
        student_id TEXT NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
        circle_id TEXT NOT NULL REFERENCES $circles(id) ON DELETE CASCADE,
        session_id TEXT REFERENCES $teachingSessions(id) ON DELETE SET NULL,
        points INTEGER NOT NULL CHECK(points > 0),
        reason TEXT NOT NULL CHECK(reason IN ('attendance', 'award', 'qa')),
        note TEXT,
        awarded_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS $qaQuestions (
        id TEXT PRIMARY KEY NOT NULL,
        circle_id TEXT NOT NULL REFERENCES $circles(id) ON DELETE CASCADE,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        created_by TEXT NOT NULL REFERENCES $users(id) ON DELETE RESTRICT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_sessions_circle_date ON $teachingSessions(circle_id, session_date)',
    'CREATE INDEX IF NOT EXISTS idx_point_ledger_circle_awarded ON $pointLedger(circle_id, awarded_at)',
    'CREATE INDEX IF NOT EXISTS idx_point_ledger_student ON $pointLedger(student_id, awarded_at)',
    'CREATE INDEX IF NOT EXISTS idx_qa_questions_circle ON $qaQuestions(circle_id)',
    'ALTER TABLE $attendance ADD COLUMN session_id TEXT',
    'ALTER TABLE $attendance ADD COLUMN attendance_date TEXT',
    '''
      UPDATE $attendance
      SET attendance_date = substr(attendance_at, 1, 10)
      WHERE attendance_date IS NULL OR attendance_date = ''
    ''',
    '''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_once_per_day
      ON $attendance(student_id, circle_id, attendance_date)
    ''',
  ];
}
