# Broker: Cash
**The ecstasy of gold**

## Purpose

**Broker: Cash** is a LibDataBroker (LDB) plugin that remembers all your characters gold balance across realms, along with daily, weekly, monthly and yearly variations.

This addon *requires* a LDB display such as [ChocolateBar](https://mods.curse.com/addons/wow/chocolatebar) (my favorite) or [Bazooka](https://mods.curse.com/addons/wow/bazooka) or whichever you prefer.

Currently available in English (default), French and German. **If you can help translating Broker: Cash to your language, please head up to GitHub and sumit a PR.**


## Details

**Broker: Cash** does not maintain a full history of your gold balance; it merely keeps track of the *variations* of your gold balance (ie. how much gold you earned or spent) on predefined periods of time.

* **Session**: variation since connected
* **Daily**: variation since today at midnight
* **Weekly**: variation since last monday at midnight
* **Monthly**: variation since the 1st of the current month at midnight
* **Yearly**: variation since January, 1st of the current year at midnight
* **Ever**: variation since Broker_Cash was installed (well, kind of - see below).

Obviously, the **Session** stat is maintained for the currently connected character only. All other stats are maintained for all your characters, account wide.

The **Daily**, **Weekly**, **Monthly** and **Yearly** stats are automatically reset at the beginning of the corresponding period. You may also reset any character's stats at any time using the `/brokercash` command - see below.

The **Ever** stat is a little special:

- First, it is never reset, so it will keep track of how much money you earned/spent since using **Broker: Cash**.
- Second, it was only added in version 1.4.0 and initially set to the same amount as the **Yearly** stat. In effect, this means that if you started using **Broker: Cash** in 2017 or later, the **Ever** stat should be accurate. But if you started using **Broker: Cash** in 2016, it misses up to two months worth of data (**Broker: Cash** 1.0 was initially released on October 16, 2016). Sorry, there is nothing I can do about that.


## Resetting or deleting statistics

Starting with 1.2.0, **Broker: Cash** allows you to reset or delete the statistics for any character it knows. Click the **Broker: Cash** LDB icon or type `/brokercash` (or simply `/bcash`) in your chat window to access this feature.


## Configuration

Starting with 1.3.0, **Broker: Cash** has a few options for you to play with. You may :

- Prevent the dropdown menu to appear while in combat, should your LDB display addon not provide this feature itself.
- Hide the copper and silver amounts in either or both the LDB display and the dropdown menu.
- Disable the secondary tooltip if you don't need it. 

Click the **Broker: Cash** LDB icon or type `/brokercash` (or simply `/bcash`) in your chat window to access the options panel.


## TODO

* Add some more locales. Help welcome: just fork the [GitHub repository](https://github.com/Septh/WoW-Broker_Cash) and submit a Pull Request


## Need help?

I rarely read comments here on Curse; should you need any help, you'd better open an issue on [GitHub](https://github.com/Septh/WoW-Broker_Cash), where the projet lives.


## Licence

Broker: Cash is released under the [MIT licence](https://opensource.org/licenses/MIT).


## Enjoy!

Also check my other addons: [BagMeters](https://www.curse.com/addons/wow/bagmeters), [BankItems_MailWatch](https://www.curse.com/addons/wow/bankitems_mailwatch) and [2048 for WoW](https://www.curse.com/addons/wow/wow2048).

If you are an addon developer, also check my [WoW Bundle for vscode](https://marketplace.visualstudio.com/items?itemName=Septh.wow-bundle) extension which brings better Lua language support and WoW API highlighting to Microsoft Visual Studio Code.

-- Septh
