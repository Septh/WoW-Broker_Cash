# Broker: Cash
**The ecstasy of gold.**

## WoW Classic Support
**Broker: Cash** for WoW Retail is available at https://www.curseforge.com/wow/addons/broker_cash  
**Broker: Cash - Classic Edition** for WoW Classic is available at https://www.curseforge.com/wow/addons/broker-cash-classic


## Purpose
**Broker: Cash** is an addon that remembers all your characters gold balance across realms, along with daily, weekly, monthly and yearly variations and displays them in a minimap icon tooltip.

This addon is also available as a LibDataBroker (LDB) plugin for LDB display such as [ChocolateBar](https://www.curseforge.com/wow/addons/chocolatebar) (my favorite), [Bazooka](https://www.curseforge.com/wow/addons/bazooka), [Titan Panel](https://www.curseforge.com/wow/addons/titan-panel) or whichever you prefer.

Currently available in English (default), French, Spanish and German. **If you can help translating Broker: Cash to your language, please head up to GitHub and sumit a PR, or PM me on Curseforge.**


## Details
**Broker: Cash** does not maintain a full history of your gold balance; it merely keeps track of the *variations* of your gold balance (ie. how much gold you earned or spent) on these predefined periods of time:

* **Session**: variation since connected
* **Daily**: variation since today at midnight
* **Weekly**: variation since last monday at midnight
* **Monthly**: variation since the 1st of the current month at midnight
* **Yearly**: variation since January, 1st of the current year at midnight
* **Ever**: variation since **Broker: Cash** was installed (well, kind of - see below).

Obviously, the **Session** stat is maintained for the currently connected character only (of course, all other stats are maintained for all your characters, account wide). This stat is *not* reset by a simple reload of the UI and since **Broker: Cash 2.1.0**, a new option called **Session threshold** allows you to set the delay before a logout is considered the end of the session. This is useful when you want to briefly connect another toon then continue playing with the current one. The default threshold is set to 60 seconds (1 minute).

The **Daily**, **Weekly**, **Monthly** and **Yearly** stats are automatically reset at the beginning of the corresponding period as described above. You may also reset any character's stats at any time using the `/brokercash` command - see below.

The **Ever** stat is a little special:

- First, it is never reset, so it will keep track of how much money you earned/spent since using **Broker: Cash**.
- Second, it was only added in version 1.4.0 and initially set to the same amount as the **Yearly** stat. In effect, this means that if you started using **Broker: Cash** in 2017 or later, the **Ever** stat should be accurate. But if you started using **Broker: Cash** in 2016, it misses up to two months worth of data (**Broker: Cash** 1.0 was initially released on October 16, 2016). Sorry, there is nothing I can do about that.


## Resetting or deleting statistics
Starting with 1.2.0, **Broker: Cash** allows you to reset or delete the statistics for any character it knows. Click the **Broker: Cash** LDB icon or type `/brokercash` (or simply `/bcash`) in your chat window to access this feature.


## Configuration
Starting with 1.3.0, **Broker: Cash** has a few options for you to play with. You may:

- Prevent the dropdown menu to appear while in combat, should your LDB display addon not provide this feature itself.
- Hide the copper and silver amounts in either or both the LDB display and the dropdown menu.
- Disable the secondary tooltip if you don't need it.

Click the **Broker: Cash** LDB icon or type `/brokercash` (or simply `/bcash`) in your chat window to access the options panel.


## TODO
* Add some more locales. Help welcome: just fork the [GitHub repository](https://github.com/Septh/WoW-Broker_Cash) and submit a Pull Request


## Need help?
I rarely read comments here on Curse; should you need any help, you'll get faster support by opening an issue on [GitHub](https://github.com/Septh/WoW-Broker_Cash), where the projet lives.


## Licence
Broker: Cash is released under the [MIT licence](https://opensource.org/licenses/MIT).


## Enjoy!
Also check my other addons: [BagMeters](https://www.curseforge.com/wow/addons/bagmeters), [BankItems_MailWatch](https://www.curseforge.com/wow/addons/bankitems_mailwatch) and [2048 for WoW](https://www.curseforge.com/wow/addons/wow2048).

If you are an addon developer, also check my [WoW Bundle for vscode](https://marketplace.visualstudio.com/items?itemName=Septh.wow-bundle) extension which brings better Lua language support and WoW API highlighting to Microsoft Visual Studio Code.

-- Septh
