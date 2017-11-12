# Broker: Cash
**The ecstasy of gold**

## Purpose

**Broker: Cash** is a LibDataBroker (LDB) plugin that remembers all your characters gold balance accross realms, along with daily, weekly, monthly and yearly variations.

This addon *requires* a LDB display such as [ChocolateBar](https://mods.curse.com/addons/wow/chocolatebar) (my favorite) or [Bazooka](https://mods.curse.com/addons/wow/bazooka) or whichever you prefer.

Currently available in English (default) and French. **If you can help translating Broker: Cash to your language, please head up to GitHub and sumit a PR.** 


## Details

**Broker: Cash** does not maintain a full history of your gold gains and losses; it merely keeps tracks of the *variations* of your gold balance on predefined periods of time.

* **Session**: variation since connected
* **Daily**: variation since midnight
* **Weekly**: variation since last monday at midnight
* **Monthly**: variation since the 1st of the current month at midnight
* **Yearly**: variation since January, 1st of the current year at midnight

Each stat is reset to 0 at the beginning of the corresponding period. You may also reset any character's stats at any time using the `/brokercash` command - see below.



## Resetting or deleting statistics

Starting with 1.2.0, **Broker: Cash** allows you to reset or delete the statistics for any character it knows. Type `/brokercash` (or `/bcash` or simply `/cash`) in your chat window to access this feature.


## Configuration

Starting with 1.3.0, **Broker: Cash** allows you to hide the copper and silver amounts in both the LDB display and the dropdown menu. Type `/brokercash` (or `/bcash` or simply `/cash`) in your chat window to access this feature.


## TODO

* Add some more locales. Help welcome: just fork the [GitHub repository](https://github.com/Septh/WoW-Broker_Cash) and submit a Pull Request


## Need help?

I rarely read comments here on Curse.com; should you need any help, you'd better open an issue on [GitHub](https://github.com/Septh/WoW-Broker_Cash), where the projet lives.


## Licence

Broker: Cash is released under the [MIT licence](https://opensource.org/licenses/MIT).


## Enjoy!

Also check my other addons: [BagMeters](https://www.curse.com/addons/wow/bagmeters), [BankItems_MailWatch](https://www.curse.com/addons/wow/bankitems_mailwatch) and [2048 for WoW](https://www.curse.com/addons/wow/wow2048).

If you are an addon developer, also check my [WoW Bundle for vscode](https://marketplace.visualstudio.com/items?itemName=Septh.wow-bundle) extension which brings better Lua language support and WoW API highlighting to Microsoft Visual Studio Code.

-- Septh
