import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiosai/bloc/settings/app_theme_bloc.dart';
import 'package:radiosai/constants/constants.dart';

/// App Theme - option to change the app theme
class AppTheme extends StatefulWidget {
  const AppTheme({super.key, this.contentPadding});

  final EdgeInsetsGeometry? contentPadding;

  @override
  State<AppTheme> createState() => _AppTheme();
}

class _AppTheme extends State<AppTheme> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeBloc>(
      // listen to change of app theme
      builder: (context, appThemeBloc, child) {
        return StreamBuilder<String?>(
          stream: appThemeBloc.appThemeStream as Stream<String?>?,
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
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: RadioGroup(
                                groupValue: appTheme,
                                onChanged: (value) {
                                  appThemeBloc.changeAppTheme.add(value);
                                  Navigator.of(context).pop();
                                },
                                child: ListView.builder(
                                  itemCount: MyConstants.of(
                                    context,
                                  )!.appThemes.length,
                                  shrinkWrap: true,
                                  primary: false,
                                  itemBuilder: (context, index) {
                                    String value = MyConstants.of(
                                      context,
                                    )!.appThemes[index];
                                    return RadioListTile(
                                      activeColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      value: value,
                                      selected: value == appTheme,
                                      title: Text(value),
                                    );
                                  },
                                ),
                              ),
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
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
