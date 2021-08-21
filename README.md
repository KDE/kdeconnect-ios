**Welcome to KDE Connect iOS 2021's Testing Repository!**

This project is inteded to be the iOS version of the group of applications called KDE Connect, which uses LAN network to integrate devices together, for information on KDE Connect, check out:

The KDE Community Wiki: https://community.kde.org/KDEConnect
The KDE Userbase Wiki: https://userbase.kde.org/KDEConnect

This project is a continuation of KDE Connect 2014, a codebase that stemmed from the Google Summer of Code 2014 program that remained largely untouched since 2014 until getting picked up again by Inoki (https://invent.kde.org/wxiao) in 2019, where some tweaks were added to it to support TLS.

KDE Connect 2021 started as a project for Google Summer of Code 2021 by student Lucas Wang. As of mid August 2021, the app compiles and is able to perform all of the functionalities currently implemented (though there are likely some bugs to be found). Currently, the app is not yet ready for Release distribution as there lacks certain functionalities compared to the other KDE Connect versions that either need to be implemented or are likely unviable to implement due to iOS restrictions.

KDE Connect iOS 2021 makes heavy use of both Swift and Objective-C, which might be a bit confusing at first, so feel free to ask the develoeprs some questions!

A testing app was made here (https://invent.kde.org/lucaswzx/swiftui-lan-testing) to test the Swift native Network framework for possible integration with this project. However, the lack of ability to start TLS on an existing TCP connection makes it unviable for the main communication of KDE Connect. It might be still suitable for the file Sharing plugin, though.

Lucas will be continuing development of the project with mentors Inoki (https://invent.kde.org/wxiao) and Philip (https://invent.kde.org/philipc), the easiest place to reach them is the KDE Connect development Telegram channel (https://planet.kde.org/t.me/joinchat/AOS6gA37orb2dZCLhqbZjg). Search their names and they should come up.

A couple useful information to get started if you would like to know more about the project:

https://lucaswangzx.xyz/kde_list contains many articles by Lucas covering technical overviews of this project as well as its origin and plans for the future.

https://community.kde.org/GSoC/2021/StatusReports/LucasWang is another place to view a report of this project from Lucas.
