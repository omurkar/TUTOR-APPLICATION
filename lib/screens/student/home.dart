import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_app/screens/common/messenger.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _search = "";
  String? _myLocation;
  String? _myProfileUrl;

  // Brand Colors
  final Color _brandBlue = const Color(0xFF2E3192);
  final Color _brandOrange = const Color(0xFFF15A24);

  @override
  void initState() {
    super.initState();
    _fetchMyData();
  }

  void _fetchMyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _myLocation = data['location'];
          _myProfileUrl = data['profileUrl'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.email?.split('@')[0] ?? 'Student';

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome back,", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _brandBlue)),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _brandBlue.withOpacity(0.1),
                        backgroundImage: _myProfileUrl != null ? NetworkImage(_myProfileUrl!) : null,
                        child: _myProfileUrl == null ? Icon(Icons.person, color: _brandBlue) : null,
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SEARCH BAR
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: "Search Tutor Name...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: _brandBlue),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- LOCATION & LIST ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Available Tutors", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        if (_myLocation != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: _brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: _brandOrange),
                                const SizedBox(width: 4),
                                Text(_myLocation!, style: TextStyle(color: _brandOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 15),

                    // LIST STREAM
                    Expanded(
                      child: StreamBuilder(
                        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'tutor').snapshots(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                          var tutors = snap.data!.docs;
                          // Filter Logic
                          tutors = tutors.where((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            bool nameMatch = _search.isEmpty || (data['name'] ?? "").toString().toLowerCase().contains(_search.toLowerCase());
                            bool locMatch = (_myLocation == null || _search.isNotEmpty) || (data['location'] ?? "").toString().toLowerCase().contains(_myLocation!.toLowerCase());
                            return nameMatch && locMatch;
                          }).toList();

                          if (tutors.isEmpty && _search.isEmpty) tutors = snap.data!.docs; // Fallback
                          if (tutors.isEmpty) return Center(child: Text("No tutors found nearby.", style: TextStyle(color: Colors.grey[400])));

                          return ListView.builder(
                            itemCount: tutors.length,
                            padding: const EdgeInsets.only(bottom: 20),
                            itemBuilder: (context, i) {
                              var tDoc = tutors[i];
                              var tData = tDoc.data() as Map<String, dynamic>;
                              return _buildTutorCard(context, tDoc.id, tData);
                            },
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorCard(BuildContext context, String id, Map<String, dynamic> data) {
    String name = data['name'] ?? 'Tutor';

    // --- SAFE SUBJECT HANDLING ---
    String subjects = "General";
    if (data.containsKey('subjects')) {
      var s = data['subjects'];
      if (s is List) {
        subjects = s.join(", ");
      } else if (s is String) {
        subjects = s;
      }
    }

    String? photo = data['profileUrl'];
    double rating = double.tryParse(data['rating'].toString()) ?? 4.5;
    int sessionCount = data['sessionCount'] ?? 0; // Number of sessions

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TutorDetailScreen(tutorId: id, tutorData: data))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Hero(
                  tag: id,
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: _brandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      image: photo != null ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null,
                    ),
                    child: photo == null ? Center(child: Text(name[0], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _brandBlue))) : null,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subjects, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text("$rating", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                            child: Text("$sessionCount Sessions", style: TextStyle(fontSize: 11, color: _brandBlue, fontWeight: FontWeight.w600)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _brandBlue.withOpacity(0.05), shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _brandBlue),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- DETAIL SCREEN ---
class TutorDetailScreen extends StatelessWidget {
  final String tutorId;
  final Map<String, dynamic> tutorData;
  const TutorDetailScreen({super.key, required this.tutorId, required this.tutorData});

  final Color _brandBlue = const Color(0xFF2E3192);

  // --- Date/Time Logic ---
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) controller.text = "${picked.day}/${picked.month}/${picked.year}";
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && context.mounted) controller.text = picked.format(context);
  }

  void _showBookingDialog(BuildContext context) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Book ${tutorData['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Select Date",
                  prefixIcon: const Icon(Icons.calendar_month),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onTap: () => _selectDate(ctx, dateController)
            ),
            const SizedBox(height: 15),
            TextField(
                controller: timeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Select Time",
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onTap: () => _selectTime(ctx, timeController)
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              if (dateController.text.isEmpty || timeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Date & Time")));
                return;
              }
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              String? studentPhoto;
              DocumentSnapshot studentDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              if (studentDoc.exists) {
                studentPhoto = (studentDoc.data() as Map<String, dynamic>)['profileUrl'];
              }

              String tSubject = "General";
              if (tutorData.containsKey('subjects')) {
                var s = tutorData['subjects'];
                if (s is List) {
                  tSubject = s.isNotEmpty ? s.join(", ") : "General";
                } else if (s is String) {
                  tSubject = s;
                }
              }

              await FirebaseFirestore.instance.collection('bookings').add({
                'studentId': user.uid,
                'studentName': user.email!.split('@')[0],
                'studentProfileUrl': studentPhoto,
                'tutorId': tutorId,
                'tutorName': tutorData['name'] ?? 'Tutor',
                'tutorProfileUrl': tutorData['profileUrl'],
                'subject': tSubject,
                'date': dateController.text,
                'time': timeController.text,
                'status': 'pending',
                'timestamp': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Request Sent!")));
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = tutorData['name'] ?? "Tutor";
    String? photo = tutorData['profileUrl'];
    int sessionCount = tutorData['sessionCount'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Hero(
                tag: tutorId,
                child: CircleAvatar(
                    radius: 50,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    backgroundColor: _brandBlue.withOpacity(0.1),
                    child: photo == null ? Text(name[0], style: TextStyle(fontSize: 40, color: _brandBlue)) : null
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(tutorData['bio'] ?? "No bio available", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 30),

            // Info Row with Sessions
            Row(children: [
              Expanded(child: _infoCard("Rate", "₹${tutorData['hourlyRate'] ?? '0'}/hr", Icons.currency_rupee)),
              const SizedBox(width: 10),
              Expanded(child: _infoCard("Sessions", "$sessionCount", Icons.class_)),
              const SizedBox(width: 10),
              Expanded(child: _infoCard("Location", tutorData['location'] ?? "Unknown", Icons.location_on)),
            ]),
            const SizedBox(height: 30),

            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IndividualChatScreen(otherUserId: tutorId, otherUserName: name))),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Chat"),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: _brandBlue),
                          foregroundColor: _brandBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      )
                  )
              ),
              const SizedBox(width: 15),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: () => _showBookingDialog(context),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("Book"),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: _brandBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      )
                  )
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
          children: [
            Icon(icon, color: _brandBlue, size: 20),
            const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey))
          ]
      ),
    );
  }
}