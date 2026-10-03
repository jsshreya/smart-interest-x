class DatabaseTables {
  // Database
  static const String databaseName = 'smart_interest_x.db';

  static const int databaseVersion = 1;

  // ------------------------------------------------------------
  // PERSON TABLE
  // ------------------------------------------------------------

  static const String personTable = 'persons';

  static const String createPersonTable =
      '''
    CREATE TABLE $personTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      email TEXT,
      type TEXT NOT NULL,
      createdAt TEXT NOT NULL
    )
  ''';

  // ------------------------------------------------------------
  // TRANSACTION TABLE
  // ------------------------------------------------------------

  static const String transactionTable = 'transactions';

  static const String createTransactionTable =
      '''
    CREATE TABLE $transactionTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      personId INTEGER NOT NULL,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      interestRate REAL NOT NULL,
      interestPeriod TEXT NOT NULL,
      startDate TEXT NOT NULL,
      dueDate TEXT,
      note TEXT,
      status TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      
      FOREIGN KEY (personId)
        REFERENCES $personTable (id)
        ON DELETE CASCADE
    )
  ''';

  // ------------------------------------------------------------
  // PAYMENT TABLE
  // ------------------------------------------------------------

  static const String paymentTable = 'payments';

  static const String createPaymentTable =
      '''
    CREATE TABLE $paymentTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transactionId INTEGER NOT NULL,
      amount REAL NOT NULL,
      paymentDate TEXT NOT NULL,
      mode TEXT NOT NULL,
      proofPath TEXT,
      note TEXT,
      createdAt TEXT NOT NULL,
      
      FOREIGN KEY (transactionId)
        REFERENCES $transactionTable (id)
        ON DELETE CASCADE
    )
  ''';
}
