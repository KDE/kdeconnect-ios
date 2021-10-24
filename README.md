**Welcome to the Official Repository of KDE Connect iOS!**

**TL;DR: Get the public testing version of KDE Connect iOS by opening [this TestFlight link](https://testflight.apple.com/join/vxCluwBF) on an iOS >= 15 device!**

Please feel free to give feedback/report bugs in the TestFlight version through:

- General information such as the number of app launches and crashes: enable Settings > Privacy > Analytics & Improvements > Share iPhone Analytics > Share with App Developers

- TestFlight's integrated screenshot feedback system: upon taking a screenshot of the app, tap "export" to see an option to send it as feedback to the developer (us).

- TestFlight's integrated crash feedback system: upon app crashing, an alert will appear asking you if you would like to send the crash data along as feedback.

- [KDE Bugzilla](https://bugs.kde.org/enter_bug.cgi?product=kdeconnect&component=ios-application).

**Data Disclosure Notice:**
- If you don't send ANY feedback AND have "Share with App Developers" disabled, the ONLY information that the KDE developers can access about you is the date that you've installed the TestFlight app.

- Enabling "Share with App Developers" discloses general information such as the number of app launches and crashes with the KDE Connect devs.

- Sending feedback through TestFlight's integrated screenshot feedback system OR TestFlight's integrated crash feedback system will disclose:

  -- User email (if chosen to disclose)
  -- Device Model
  -- iOS version
  -- Battery level
  -- Cellular carrier (if applicable)
  -- Time zone
  -- Architecture
  -- Connection Type (Wifi, etc.)
  -- Free space on disk and total disk space available
  -- Screen resolution
  -- (For Crash feedback) stack trace leading to crash
   
- Sending feedback through [KDE Bugzilla](https://bugs.kde.org/enter_bug.cgi?product=kdeconnect&component=ios-application) lets you manually disclose as much or as little information as you would like, but all information will have to be investigated manually.

**TestFlight version known behavior and problems:**

-  iOS is very much designed around foreground interactions. Therefore, background “daemon-style” applications don’t really exist under conventional means, so the behavior where KDE Connect iOS is unresponsive in the background is more or less intended. There are technically some special categories and "hacky" methods to try to get it to run in the background, but in general, there is no intended/by-design method of keeping a "daemon-style" app running forever in the background. For more information, see [this post on the Apple Dev Forums](https://developers.apple.com/forums/thread/685525).

- Miscellaneous crashes (under investigation).

- Run Command doesn't work.

- Presenter for the desktop is not exposed to the user.



This project is intended to be the iOS version of the group of applications called KDE Connect, which uses the LAN network to integrate devices together, for information on KDE Connect, check out:

[The KDE Community Wiki](https://community.kde.org/KDEConnect)
[The KDE Userbase Wiki](https://userbase.kde.org/KDEConnect)

If you would like to talk to the KDE Connect developers & contributors (for questions or if you would like to contribute!), please go to [KDE Connect development Telegram channel](https://planet.kde.org/t.me/joinchat/AOS6gA37orb2dZCLhqbZjg)

**Plans & To-Dos (great for contributions!):**

- Instead of using all generics, a fair amount of Obj-C code could have type explicitly stated to avoid force casting in Swift all over the place.

- Instead of the single-alert system, perhaps the app can implement some other sort of in-app notification system? (iOS cannot display system notifications while the app responsible for them is in the foreground)

- Add "send with KDE Connect" in the "Share" menu so files can be sent from anywhere (need to wake up KDE Connect though, is this possible?)

- Expand to a watchOS companion app?

- Expand to macOS with catalyst?

------------------------------------------------------------------------------------------------------------------------------------------------------

If you would like to check out some other posts about KDE Connect iOS, please see:

[Lucas's blog](https://lucaswangzx.xyz/kde_list) contains many articles covering technical overviews of this project as well as its origin and plans for the future.

[Lucas's Google Summer of Code Status Report](https://community.kde.org/GSoC/2021/StatusReports/LucasWang) is another place to view a report of this project.

**For a lengthy history of KDE Connect iOS, please take a look at:**

This project is a continuation of KDE Connect 2014, a codebase that stemmed from the Google Summer of Code 2014 program that remained largely untouched since 2014 until getting picked up again by [Inoki](https://invent.kde.org/wxiao) in 2019, where some tweaks were added to it to support TLS.

KDE Connect 2021 was started as a project for Google Summer of Code 2021 by student Lucas Wang. As of mid-August 2021, the app compiles and is able to perform all of the functionalities currently implemented (though there are likely some bugs to be found). Currently, the app is not yet ready for Release distribution as it lacks certain functionalities compared to the other KDE Connect versions that either need to be implemented or are likely unviable to implement due to iOS restrictions.

KDE Connect iOS 2021 makes heavy use of both Swift and Objective-C, which might be a bit confusing at first, so feel free to ask the developers some questions!
