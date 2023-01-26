import 'package:flutter/material.dart';

@pragma('vm:entry-point')
DateTime calAlarDay(DateTime ltBaseDay, bool monFlg, bool tueFlg, bool wedFlg,
    bool thuFlg, bool friFlg, bool satFlg, bool sunFlg,) {
  DateTime ltDtAlarmDayTime = ltBaseDay;
  int weekDayCnt = ltBaseDay.weekday;
  bool weekOK = false;
  int cnt = 1;

  while (cnt <= 7) {
    switch (weekDayCnt) {
      case 1:
        if (monFlg) {
          weekOK = true;
        } else {
          ltDtAlarmDayTime = ltDtAlarmDayTime.add(const Duration(days: 1));
        }
        break;
      case 2:
        if (tueFlg) {
          weekOK = true;
        } else {
          ltDtAlarmDayTime = ltDtAlarmDayTime.add(const Duration(days: 1));
        }
        break;
      case 3:
        if (wedFlg) {
          weekOK = true;
        } else {
          ltDtAlarmDayTime = ltDtAlarmDayTime.add(const Duration(days: 1));
        }
        break;
      case 4:
        if (thuFlg) {
          weekOK = true;
        } else {
          ltDtAlarmDayTime = ltDtAlarmDayTime.add(const Duration(days: 1));
        }
        break;
      case 5:
        if (friFlg) {
          weekOK = true;
        } else {
          ltDtAlarmDayTime = ltDtAlarmDayTime.add(const Duration(days: 1));
        }
        break;
      case 6:
        if (satFlg) {
          weekOK = true;
        } else {
          ltDtAlarmDayTime = ltDtAlarmDayTime.add(const Duration(days: 1));
        }
        break;
      case 7:
        if (sunFlg) {
          weekOK = true;
        } else {
          ltDtAlarmDayTime = ltDtAlarmDayTime.add(const Duration(days: 1));
        }
        break;
    }
    if (weekOK) {
      break;
    }
    weekDayCnt++;
    if (weekDayCnt == 8) {
      weekDayCnt = 1;
    }
    cnt++;
  }
  return ltDtAlarmDayTime;
}

bool chkWeek(BuildContext context,bool monFlg,bool tueFlg,bool wedFlg,bool thuFlg,bool friFlg,bool satFlg,bool sunFlg) {
  if (monFlg == false && tueFlg == false && wedFlg == false &&
      thuFlg == false && friFlg == false && satFlg == false &&
      sunFlg == false) {
    debugPrint('必ず曜日を設定してください');
    showDialog(context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("警告"),
          content: Text("必ず曜日を設定してください。"),
          actions: <Widget>[
            TextButton(onPressed: () => { Navigator.pop(context)},
              child: const Text('閉じる'),),
          ],
        );
      },
    );
    return false;
  }else {
    return true;
  }
}