import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/settings/app_theme_bloc.dart';
import 'package:radiosai/constants/constants.dart';

/// App Theme - option to change the app theme
class AppTheme extends StatefulWidget {
  const AppTheme({
    Key? key,
    this.contentPadding,
  }) : super(key: key);

  final EdgeInsetsGeometry? contentPadding;

  @override
  _AppTheme createState() => _AppTheme();
}

class _AppTheme extends State<AppTheme> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeBloc>(
        // listen to change of app theme
        builder: (context, _appThemeBloc, child) {
      return StreamBuilder<String?>(
          stream: _appThemeBloc.appThemeStream as Stream<String?>?,
          builder: (context, snapshot) {
            String appTheme =
                snapshot.data ?? MyConstants.of(context)!.appThemes[2];

            return Tooltip(
              message: 'change app theme',
              child: ListTile(
                contentPadding: widget.contentPadding,
                title: const Text('Theme'),
                subtitle: Text(appTheme),
                onTap: () async {
                  showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Change Theme'),
                          contentPadding: const EdgeInsets.only(top: 10),
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: Scrollbar(
                              radius: const Radius.circular(8),
                              isAlwaysShown: true,
                              child: SingleChildScrollView(
                                child: ListView.builder(
                                    itemCount: MyConstants.of(context)!
                                        .appThemes
                                        .length,
                                    shrinkWrap: true,
                                    primary: false,
                                    itemBuilder: (context, index) {
                                      String value = MyConstants.of(context)!
                                          .appThemes[index];
                                      return RadioListTile(
                                          activeColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          value: value,
                                          selected: value == appTheme,
                                          title: Text(value),
                                          groupValue: appTheme,
                                          onChanged: (dynamic value) {
                                            _appThemeBloc.changeAppTheme
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
