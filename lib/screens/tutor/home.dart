import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_app/screens/common/messenger.dart';

class TutorHomeScreen extends StatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Brand Colors
  final Color _brandBlue = const Color(0xFF2E3192);
  final Color _brandOrange = const Color(0xFFF15A24);

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': newStatus,
    });
    String message = newStatus == 'completed' ? "Session Marked as Completed! ✅" : "Booking $newStatus";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Not Logged In"));

    return Scaffold(
      backgroundColor: Colors.grey[50], // Modern background
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. HEADER SECTION ---
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                String? myPhotoUrl;
                String myName = "Tutor";

                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  myPhotoUrl = data['profileUrl'];
                  myName = data['name'] ?? "Tutor";
                }

                return Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hello, $myName! 👋", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          const SizedBox(height: 5),
                          Text("Your Dashboard", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _brandBlue)),
                        ],
                      ),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _brandBlue.withOpacity(0.1),
                        backgroundImage: myPhotoUrl != null ? NetworkImage(myPhotoUrl) : null,
                        child: myPhotoUrl == null
                            ? Text(myName.isNotEmpty ? myName[0] : "T", style: TextStyle(fontWeight: FontWeight.bold, color: _brandBlue, fontSize: 24))
                            : null,
                      )
                    ],
                  ),
                );
              },
            ),

            // --- 2. SCROLLABLE CONTENT ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('tutorId', isEqualTo: user!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var allDocs = snapshot.data!.docs;
                  var pending = allDocs.where((d) => d['status'] == 'pending').toList();
                  var accepted = allDocs.where((d) => d['status'] == 'accepted').toList();
                  var completed = allDocs.where((d) => d['status'] == 'completed').toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 3. STATS CARDS ---
                        Row(
                          children: [
                            _buildCountCard("Upcoming", accepted.length.toString(), _brandBlue, Icons.calendar_today),
                            const SizedBox(width: 15),
                            _buildCountCard("Completed", completed.length.toString(), Colors.green, Icons.check_circle_outline),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // --- 4. NEW REQUESTS ---
                        if (pending.isNotEmpty) ...[
                          Text("New Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brandOrange)),
                          const SizedBox(height: 15),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pending.length,
                            itemBuilder: (context, index) {
                              var data = pending[index].data() as Map<String, dynamic>;
                              String? sPhoto = data['studentProfileUrl'];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _brandOrange.withOpacity(0.2)),
                                  boxShadow: [BoxShadow(color: _brandOrange.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: _brandOrange.withOpacity(0.1),
                                            backgroundImage: sPhoto != null ? NetworkImage(sPhoto) : null,
                                            child: sPhoto == null ? Text((data['studentName']??"S")[0], style: TextStyle(color: _brandOrange, fontWeight: FontWeight.bold)) : null,
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(data['studentName'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                Text("${data['subject']} • ${data['date']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _updateBookingStatus(pending[index].id, 'declined'),
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200)),
                                              child: const Text("Decline"),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _updateBookingStatus(pending[index].id, 'accepted'),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                                              child: const Text("Accept"),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // --- 5. UPCOMING SCHEDULE ---
                        const Text("Upcoming Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        if (accepted.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                Icon(Icons.event_busy, size: 40, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                Text("No upcoming sessions.", style: TextStyle(color: Colors.grey[400])),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: accepted.length,
                            itemBuilder: (context, index) {
                              var data = accepted[index].data() as Map<String, dynamic>;
                              String? sPhoto = data['studentProfileUrl'];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: _brandBlue.withOpacity(0.1),
                                      backgroundImage: sPhoto != null ? NetworkImage(sPhoto) : null,
                                      child: sPhoto == null ? Text((data['studentName']??"S")[0], style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold)) : null,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(data['studentName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text("${data['subject']} • ${data['date']} @ ${data['time']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.chat_bubble_outline, color: _brandBlue),
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => IndividualChatScreen(
                                                    otherUserId: data['studentId'],
                                                    otherUserName: data['studentName']
                                                )
                                            ));
                                          },
                                        ),
                                        InkWell(
                                          onTap: () => _updateBookingStatus(accepted[index].id, 'completed'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: const Text("Finish", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          ),

                        // --- 6. COMPLETED HISTORY ---
                        if (completed.isNotEmpty) ...[
                          const SizedBox(height: 30),
                          ExpansionTile(
                            title: Text("Completed History (${completed.length})", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                            tilePadding: EdgeInsets.zero,
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: completed.length,
                                itemBuilder: (context, index) {
                                  var data = completed[index].data() as Map<String, dynamic>;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.check_circle, color: Colors.green),
                                    title: Text(data['studentName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("Completed on ${data['date']}"),
                                  );
                                },
                              )
                            ],
                          ),
                        ]
                      ],
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

  Widget _buildCountCard(String label, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 15),
            Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}