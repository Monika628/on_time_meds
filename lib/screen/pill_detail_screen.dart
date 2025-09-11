import 'package:flutter/material.dart';
import 'package:on_time_meds/model/pill_model.dart';


class PillDetailScreen extends StatelessWidget {
  final PillModel pill;

  const PillDetailScreen({super.key, required this.pill});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text('Details',style: TextStyle(color: Colors.black),),
        leading: BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.medication, size: 60, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text("Medicine Name", style: TextStyle(color: Colors.grey)),
            Text(pill.pillName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("Dosage", style: TextStyle(color: Colors.grey)),
            Text("${pill.dosage} mg", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("Medicine Type", style: TextStyle(color: Colors.grey)),
            Text(pill.types?.join(", ") ?? "N/A", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("Dose Interval", style: TextStyle(color: Colors.grey)),
            Text("Every ${pill.interval} hours | ${24 ~/ pill.interval} times a day",
                style: TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            Text("Start Time", style: TextStyle(color: Colors.grey)),
            Text("${pill.time.hour.toString().padLeft(2, '0')}:${pill.time.minute.toString().padLeft(2, '0')}",
                style: TextStyle(fontSize: 16)),
            const Spacer(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, pill.id); // Return pill id to HomeScreen
                  },
                  icon: const Icon(Icons.delete, color: Colors.black),
                  label: const Text(
                    "Delete",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
