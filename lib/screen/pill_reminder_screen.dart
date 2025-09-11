import 'package:flutter/material.dart';

class PillReminderScreen extends StatelessWidget {
  const PillReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pill Reminder")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Medicine Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Reminder Time: "),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    // Show time picker
                  },
                  child: const Text("Pick Time"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Save and schedule reminder
              },
              icon: const Icon(Icons.alarm),
              label: const Text("Set Reminder"),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const Text(
              "Scheduled Reminders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Example
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.medication),
                    title: const Text("Paracetamol"),
                    subtitle: const Text("Reminder: 9:00 AM"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Cancel reminder
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
