import '../models/payment.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_tables.dart';
import '../models/person.dart';
import '../models/transaction.dart';

class DatabaseService {
  static Database? _database;

  // ------------------------------------------------------------
  // DATABASE INSTANCE
  // ------------------------------------------------------------

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();

    return _database!;
  }

  // ------------------------------------------------------------
  // INITIALIZE DATABASE
  // ------------------------------------------------------------

  Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, DatabaseTables.databaseName);

    return await openDatabase(
      path,
      version: DatabaseTables.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ------------------------------------------------------------
  // DATABASE CONFIGURATION
  // ------------------------------------------------------------

  Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  // ------------------------------------------------------------
  // CREATE TABLES
  // ------------------------------------------------------------

  Future<void> _onCreate(Database database, int version) async {
    await database.execute(DatabaseTables.createPersonTable);

    await database.execute(DatabaseTables.createTransactionTable);

    await database.execute(DatabaseTables.createPaymentTable);
  }

  // ------------------------------------------------------------
  // DATABASE UPGRADES
  // ------------------------------------------------------------

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migrations will be added here.
  }

  // ============================================================
  // PERSON CRUD
  // ============================================================

  Future<int> insertPerson(Person person) async {
    final database = await this.database;

    return await database.insert(
      DatabaseTables.personTable,
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Person>> getAllPeople() async {
    final database = await this.database;

    final result = await database.query(
      DatabaseTables.personTable,
      orderBy: 'createdAt DESC',
    );

    return result.map((map) => Person.fromMap(map)).toList();
  }

  Future<Person?> getPersonById(int id) async {
    final database = await this.database;

    final result = await database.query(
      DatabaseTables.personTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Person.fromMap(result.first);
  }

  Future<int> updatePerson(Person person) async {
    if (person.id == null) {
      throw Exception('Cannot update a person without an ID.');
    }

    final database = await this.database;

    return await database.update(
      DatabaseTables.personTable,
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> deletePerson(int id) async {
    final database = await this.database;

    return await database.delete(
      DatabaseTables.personTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Person>> searchPeople(String query) async {
    final database = await this.database;

    final result = await database.query(
      DatabaseTables.personTable,
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return result.map((map) => Person.fromMap(map)).toList();
  }

  // ============================================================
  // TRANSACTION CRUD
  // ============================================================

  // ------------------------------------------------------------
  // CREATE TRANSACTION
  // ------------------------------------------------------------

  Future<int> insertTransaction(LoanTransaction transaction) async {
    final database = await this.database;

    return await database.insert(
      DatabaseTables.transactionTable,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ------------------------------------------------------------
  // GET ALL TRANSACTIONS
  // ------------------------------------------------------------

  Future<List<LoanTransaction>> getAllTransactions() async {
    final database = await this.database;

    final result = await database.query(
      DatabaseTables.transactionTable,
      orderBy: 'startDate DESC',
    );

    return result.map((map) => LoanTransaction.fromMap(map)).toList();
  }

  // ------------------------------------------------------------
  // GET TRANSACTION BY ID
  // ------------------------------------------------------------

  Future<LoanTransaction?> getTransactionById(int id) async {
    final database = await this.database;

    final result = await database.query(
      DatabaseTables.transactionTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return LoanTransaction.fromMap(result.first);
  }

  // ------------------------------------------------------------
  // GET TRANSACTIONS FOR A PERSON
  // ------------------------------------------------------------

  Future<List<LoanTransaction>> getTransactionsForPerson(int personId) async {
    final database = await this.database;

    final result = await database.query(
      DatabaseTables.transactionTable,
      where: 'personId = ?',
      whereArgs: [personId],
      orderBy: 'startDate DESC',
    );

    return result.map((map) => LoanTransaction.fromMap(map)).toList();
  }

  // ------------------------------------------------------------
  // UPDATE TRANSACTION
  // ------------------------------------------------------------

  Future<int> updateTransaction(LoanTransaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Cannot update a transaction without an ID.');
    }

    final database = await this.database;

    return await database.update(
      DatabaseTables.transactionTable,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // ------------------------------------------------------------
  // DELETE TRANSACTION
  // ------------------------------------------------------------

  Future<int> deleteTransaction(int id) async {
    final database = await this.database;

    return await database.delete(
      DatabaseTables.transactionTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  // ============================================================
  // PAYMENT CRUD
  // ============================================================

  // ------------------------------------------------------------
  // INSERT PAYMENT
  // ------------------------------------------------------------

  Future<int> insertPayment(Payment payment) async {
    final database = await this.database;

    return await database.insert(
      DatabaseTables.paymentTable,
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ------------------------------------------------------------
  // GET ALL PAYMENTS
  // ------------------------------------------------------------

  Future<List<Payment>> getAllPayments() async {
    final database = await this.database;

    final result = await database.query(
      DatabaseTables.paymentTable,
      orderBy: 'paymentDate DESC',
    );

    return result.map((map) => Payment.fromMap(map)).toList();
  }

  // ------------------------------------------------------------
  // GET PAYMENT BY ID
  // ------------------------------------------------------------

  Future<Payment?> getPaymentById(int id) async {
    final database = await this.database;

    final result = await database.query(
      DatabaseTables.paymentTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Payment.fromMap(result.first);
  }

  // ------------------------------------------------------------
  // GET PAYMENTS FOR A TRANSACTION
  // ------------------------------------------------------------

  Future<List<Payment>> getPaymentsForTransaction(int transactionId) async {
    final database = await this.database;

    final result = await database.query(
      DatabaseTables.paymentTable,
      where: 'transactionId = ?',
      whereArgs: [transactionId],
      orderBy: 'paymentDate DESC',
    );

    return result.map((map) => Payment.fromMap(map)).toList();
  }

  // ------------------------------------------------------------
  // UPDATE PAYMENT
  // ------------------------------------------------------------

  Future<int> updatePayment(Payment payment) async {
    if (payment.id == null) {
      throw Exception('Cannot update a payment without an ID.');
    }

    final database = await this.database;

    return await database.update(
      DatabaseTables.paymentTable,
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  // ------------------------------------------------------------
  // DELETE PAYMENT
  // ------------------------------------------------------------

  Future<int> deletePayment(int id) async {
    final database = await this.database;

    return await database.delete(
      DatabaseTables.paymentTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------------------------------
  // GET TOTAL PAID FOR A TRANSACTION
  // ------------------------------------------------------------

  Future<double> getTotalPaidForTransaction(int transactionId) async {
    final database = await this.database;

    final result = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS totalPaid
      FROM ${DatabaseTables.paymentTable}
      WHERE transactionId = ?
      ''',
      [transactionId],
    );

    final total = result.first['totalPaid'];

    return (total as num).toDouble();
  }

  // ------------------------------------------------------------
  // CLOSE DATABASE
  // ------------------------------------------------------------

  Future<void> closeDatabase() async {
    final database = await this.database;

    await database.close();

    _database = null;
  }
}
