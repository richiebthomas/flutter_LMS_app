import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewSubmissionsScreen extends StatelessWidget {
  final String assignmentId;
  final String assignmentTitle;

  const ViewSubmissionsScreen({
    required this.assignmentId,
    required this.assignmentTitle,
    super.key,
  });

  Future<void> _openSubmission(String fileUrl) async {
    if (await canLaunch(fileUrl)) {
      await launch(fileUrl);
    } else {
      throw 'Could not launch $fileUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submissions for $assignmentTitle'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Modified query to avoid needing a composite index
        stream: FirebaseFirestore.instance
            .collection('submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final submissions = snapshot.data!.docs;

          if (submissions.isEmpty) {
            return Center(
              child: Text(
                'No submissions yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index].data() as Map<String, dynamic>;
              final submittedAt = (submission['submittedAt'] as Timestamp)
                  .toDate();

              return Card(
                child: ListTile(
                  leading: Icon(Icons.assignment_turned_in),
                  title: Text(submission['fileName'] ?? 'Unnamed file'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student: ${submission['studentName'] ?? 'Unknown'}'),
                      Text(
                        'Submitted on ${submittedAt.toString().split('.')[0]}',
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.open_in_new),
                    onPressed: () => _openSubmission(submission['fileUrl']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}