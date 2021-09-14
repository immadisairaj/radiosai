import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/radio/radio_index_bloc.dart';
import 'package:radiosai/bloc/radio_schedule/time_zone_bloc.dart';
import 'package:radiosai/screens/radio_schedule/schedule_data.dart';

class RadioSchedule extends StatefulWidget {
  const RadioSchedule({
    Key key,
  }) : super(key: key);

  @override
  _RadioSchedule createState() => _RadioSchedule();
}

class _RadioSchedule extends State<RadioSchedule> {
  @override
  Widget build(BuildContext context) {
    // Consumers of all the providers to get the stream of data
    return Consumer<RadioIndexBloc>(
        // listen to change of radio stream index
        builder: (context, _radioIndexBloc, child) {
      return StreamBuilder<int>(
          stream: _radioIndexBloc.radioIndexStream,
          builder: (context, snapshot) {
            int radioStreamIndex = snapshot.data ?? -1;

            // schedule doesn't have bhajan stream
            if (radioStreamIndex == 3) radioStreamIndex = 0;

            return Consumer<TimeZoneBloc>(
              // listen to change of time zone
              builder: (context, _timeZoneBloc, child) {
                return StreamBuilder<String>(
                  stream: _timeZoneBloc.timeZoneStream,
                  builder: (context, snapshot) {
                    String timeZone = snapshot.data ?? 'INDIA';

                    return ScheduleData(
                      radioStreamIndex: radioStreamIndex,
                      timeZone: timeZone,
                      timeZoneBloc: _timeZoneBloc,
                    );
                  },
                );
              },
            );
          });
    });
  }
}
