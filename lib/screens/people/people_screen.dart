import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../providers/person_provider.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonProvider>().loadPeople();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // ADD / EDIT PERSON DIALOG
  // ------------------------------------------------------------

  void _showPersonDialog({Person? person}) {
    final nameController = TextEditingController(text: person?.name ?? '');

    final phoneController = TextEditingController(text: person?.phone ?? '');

    final emailController = TextEditingController(text: person?.email ?? '');

    String selectedType = person?.type ?? 'Borrower';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(person == null ? 'Add Person' : 'Edit Person'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Person Type',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Borrower'),
                            selected: selectedType == 'Borrower',
                            onSelected: (_) {
                              setDialogState(() {
                                selectedType = 'Borrower';
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Lender'),
                            selected: selectedType == 'Lender',
                            onSelected: (_) {
                              setDialogState(() {
                                selectedType = 'Lender';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    final phone = phoneController.text.trim();

                    final email = emailController.text.trim();

                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and mobile number are required.'),
                        ),
                      );

                      return;
                    }

                    final provider = context.read<PersonProvider>();

                    if (person == null) {
                      final newPerson = Person(
                        name: name,
                        phone: phone,
                        email: email.isEmpty ? null : email,
                        type: selectedType,
                        createdAt: DateTime.now(),
                      );

                      await provider.addPerson(newPerson);
                    } else {
                      final updatedPerson = person.copyWith(
                        name: name,
                        phone: phone,
                        email: email.isEmpty ? null : email,
                        type: selectedType,
                      );

                      await provider.updatePerson(updatedPerson);
                    }

                    if (mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(person == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // DELETE PERSON
  // ------------------------------------------------------------

  void _confirmDelete(Person person) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Person?'),
          content: Text('Are you sure you want to delete ${person.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () async {
                if (person.id != null) {
                  await context.read<PersonProvider>().deletePerson(person.id!);
                }

                if (mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'People',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: Consumer<PersonProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    provider.search(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearch();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          )
                        : null,
                  ),
                ),
              ),

              // People list
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.people.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: provider.people.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final person = provider.people[index];

                          return _buildPersonCard(person);
                        },
                      ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showPersonDialog();
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Person'),
      ),
    );
  }

  // ------------------------------------------------------------
  // PERSON CARD
  // ------------------------------------------------------------

  Widget _buildPersonCard(Person person) {
    final isBorrower = person.type == 'Borrower';

    final color = isBorrower ? Colors.orange : Colors.blue;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        leading: CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(0.10),
          child: Text(
            person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),

        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            Text(person.phone),

            const SizedBox(height: 4),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                person.type,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showPersonDialog(person: person);
            } else if (value == 'delete') {
              _confirmDelete(person);
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ];
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No People Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            Text(
              'Add your first borrower or lender to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                _showPersonDialog();
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Person'),
            ),
          ],
        ),
      ),
    );
  }
}
