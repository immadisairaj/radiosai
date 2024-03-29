import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/settings/initial_radio_index_bloc.dart';
import 'package:radiosai/constants/constants.dart';

const String recentlyPlayed = 'Recently played';

/// StartingRadioStream - Option to change the radio stream open on app start
class StartingRadioStream extends StatefulWidget {
  const StartingRadioStream({
    super.key,
    this.contentPadding,
  });

  final EdgeInsetsGeometry? contentPadding;

  @override
  State<StartingRadioStream> createState() => _StartingRadioStream();
}

class _StartingRadioStream extends State<StartingRadioStream> {
  @override
  Widget build(BuildContext context) {
    return Consumer<InitialRadioIndexBloc>(
        // listen to change of initial radio stream index
        builder: (context, initialRadioIndexBloc, child) {
      return StreamBuilder<int?>(
          stream:
              initialRadioIndexBloc.initialRadioIndexStream as Stream<int?>?,
          builder: (context, snapshot) {
            int initialRadioStreamIndex = snapshot.data ?? -1;

            // default to recently playing stream if the index
            // is out of length
            final length = MyConstants.of(context)!.radioStreamHttps.length;
            if (!(initialRadioStreamIndex >= -1 &&
                initialRadioStreamIndex < length)) {
              initialRadioIndexBloc.changeInitialRadioIndex.add(-1);
              return const Text('Please wait!');
            }

            String subtitle = (initialRadioStreamIndex >= 0)
                ? MyConstants.of(context)!
                    .radioStreamHttps
                    .keys
                    .toList()[initialRadioStreamIndex]
                : recentlyPlayed;

            return Tooltip(
              message: 'favourite radio stream to show on app start',
              child: ListTile(
                contentPadding: widget.contentPadding,
                title: const Text('Starting radio stream'),
                subtitle: Text(subtitle),
                onTap: () async {
                  showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Starting radio stream'),
                          contentPadding: const EdgeInsets.only(top: 10),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: Scrollbar(
                              radius: const Radius.circular(8),
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                child: ListView.builder(
                                    itemCount: MyConstants.of(context)!
                                            .radioStreamHttps
                                            .length +
                                        1,
                                    shrinkWrap: true,
                                    primary: false,
                                    itemBuilder: (context, index) {
                                      int value = index - 1;
                                      return RadioListTile(
                                          activeColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          value: value,
                                          selected:
                                              value == initialRadioStreamIndex,
                                          title: (value >= 0)
                                              ? Text(MyConstants.of(context)!
                                                  .radioStreamHttps
                                                  .keys
                                                  .toList()[value])
                                              : const Text(recentlyPlayed),
                                          groupValue: initialRadioStreamIndex,
                                          onChanged: (dynamic value) {
                                            initialRadioIndexBloc
                                                .changeInitialRadioIndex
                                                .add(value);
                                            Navigator.of(context).pop();
                                          });
                                    }),
                              ),
                            ),
                          ),
                          buttonPadding: const EdgeInsets.all(4),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        );
                      });
                },
              ),
            );
          });
    });
  }
}
