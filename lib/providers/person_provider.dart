import 'package:flutter/material.dart';

import '../models/person.dart';
import '../services/database_service.dart';

class PersonProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Person> _people = [];

  bool _isLoading = false;

  String _searchQuery = '';

  List<Person> get people => _people;

  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;

  // ------------------------------------------------------------
  // LOAD PEOPLE
  // ------------------------------------------------------------

  Future<void> loadPeople() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_searchQuery.isEmpty) {
        _people = await _databaseService.getAllPeople();
      } else {
        _people = await _databaseService.searchPeople(_searchQuery);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // ADD PERSON
  // ------------------------------------------------------------

  Future<void> addPerson(Person person) async {
    await _databaseService.insertPerson(person);

    await loadPeople();
  }

  // ------------------------------------------------------------
  // UPDATE PERSON
  // ------------------------------------------------------------

  Future<void> updatePerson(Person person) async {
    await _databaseService.updatePerson(person);

    await loadPeople();
  }

  // ------------------------------------------------------------
  // DELETE PERSON
  // ------------------------------------------------------------

  Future<void> deletePerson(int id) async {
    await _databaseService.deletePerson(id);

    await loadPeople();
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  Future<void> search(String query) async {
    _searchQuery = query;

    await loadPeople();
  }

  // ------------------------------------------------------------
  // CLEAR SEARCH
  // ------------------------------------------------------------

  Future<void> clearSearch() async {
    _searchQuery = '';

    await loadPeople();
  }
}
