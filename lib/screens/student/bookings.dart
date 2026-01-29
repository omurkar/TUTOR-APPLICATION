import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedBookingScreen extends StatelessWidget {
  final bool isTutor;
  const SharedBookingScreen({super.key, required this.isTutor});

  final Color _brandBlue = const Color(0xFF2E3192);

  // --- RATING LOGIC ---
  void _showRatingDialog(BuildContext context, String docId, String tutorId, String tutorName) {
    final commentController = TextEditingController();
    int selectedStars = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Rate $tutorName", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("How was your session?", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                          onPressed: () => setState(() => selectedStars = index + 1),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: "Write a review...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Skip", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (selectedStars == 0) return;

                      // 1. Add Review to Tutor's subcollection
                      await FirebaseFirestore.instance.collection('users').doc(tutorId).collection('reviews').add({
                        'rating': selectedStars,
                        'comment': commentController.text,
                        'studentName': FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? "Anonymous",
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      // 2. Mark booking as rated
                      await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'isRated': true});

                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text("Submit", style: TextStyle(color: Colors.white))
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    String fieldToCheck = isTutor ? 'tutorId' : 'studentId';

    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern off-white background
      appBar: AppBar(
        title: const Text("My Schedule", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('bookings').where(fieldToCheck, isEqualTo: user.uid).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var allDocs = snapshot.data!.docs;

          // Horizontal "Kanban" Scroll View
          return ListView(
            padding: const EdgeInsets.all(20),
            scrollDirection: Axis.horizontal,
            children: [
              _buildColumn(context, "Requests", Colors.orange, allDocs.where((d) => d['status'] == 'pending').toList()),
              _buildColumn(context, "Upcoming", _brandBlue, allDocs.where((d) => d['status'] == 'accepted').toList()),
              _buildColumn(context, "Completed", Colors.green, allDocs.where((d) => d['status'] == 'completed').toList()),
            ],
          );
        },
      ),
    );
  }

  // --- KANBAN COLUMN WIDGET ---
  Widget _buildColumn(BuildContext context, String title, Color color, List<QueryDocumentSnapshot> docs) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Text("${docs.length}", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 15),

          // Cards List
          Expanded(
            child: docs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 40, color: Colors.grey[200]),
                  const SizedBox(height: 10),
                  Text("Empty", style: TextStyle(color: Colors.grey[300], fontWeight: FontWeight.bold)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var doc = docs[index];
                var data = doc.data() as Map<String, dynamic>;
                String status = data['status'];
                bool isRated = data['isRated'] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.04), // Light tint background
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                        child: Text(data['subject'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
                      ),
                      const SizedBox(height: 10),

                      // Names & Time
                      Text(isTutor ? data['studentName'] : data['tutorName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text("${data['date']} • ${data['time']}", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --- ACTION BUTTONS ---
                      if (isTutor && status == 'accepted')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 0)
                            ),
                            onPressed: () => FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({'status': 'completed'}),
                            child: const Text("Mark Complete", style: TextStyle(fontSize: 12)),
                          ),
                        ),

                      if (!isTutor && status == 'completed' && !isRated)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 0)
                            ),
                            onPressed: () => _showRatingDialog(context, doc.id, data['tutorId'], data['tutorName']),
                            child: const Text("Rate Session", style: TextStyle(fontSize: 12)),
                          ),
                        ),

                      if (status == 'completed' && isRated)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Center(child: Text("Rated", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}