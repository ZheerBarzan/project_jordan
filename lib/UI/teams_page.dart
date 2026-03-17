import 'package:flutter/material.dart';
import 'package:project_jordan/model/teams.dart';
import 'package:project_jordan/services/nba_api_service.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final NbaApiService _nbaApiService = NbaApiService();
  late final Future<List<Team>> _futureTeams;

  @override
  void initState() {
    super.initState();
    _futureTeams = _nbaApiService.fetchTeams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Team>>(
        future: _futureTeams,
        builder: (BuildContext context, AsyncSnapshot<List<Team>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            final List<Team> teams = snapshot.data!;
            return ListView.builder(
              itemCount: teams.length,
              itemBuilder: (BuildContext context, int index) {
                final Team team = teams[index];
                return ListTile(
                  title: Row(
                    children: <Widget>[
                      Image.asset('images/nba/LAL.png', height: 20, width: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${team.abbreviation}, ${team.city}, ${team.fullName}',
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
