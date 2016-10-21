# Broker: Cash
**The ecstasy of gold**

## Purpose

Broker: Cash is a LibDataBroker plugin that remembers all your characters gold balance along with daily, weekly, monthly and yearly variations.

This addon requires a LDB display such as [ChocolateBar](https://mods.curse.com/addons/wow/chocolatebar) (my favorite) or [Bazooka](https://mods.curse.com/addons/wow/bazooka) or whichever you prefer.

Currently available in English (default) and French.


## Details

Broker: Cash does not maintain a full history of your gold gains and losses; it merely keeps tracks of the *variations* of your gold balance.

* **Daily**: variation since midnight
* **Weekly**: variation since past monday at midnight
* **Monthly**: variation since the 1st of the current month at midnight
* **Yearly**: variation since January, 1st of the current year at midnight

Each stat is reset to 0 at the beginning of the corresponding period.

Also, a special **session** statistic shows how much gold the current character earned or spent since connection.


## Configuration

There is no user configurable options. Just install and enjoy!


## TODO

* There is currently no way to delete or reset a character's stats; I'll add this functionnality in a future release.
* Add some more locales. Help welcome: just fork the [GitHub repository](https://github.com/Septh/WoW-Broker_Cash) and submit a Pull Request



## Need help?

I rarely read comments here on Curse.com; should you need any help, you'd better open an issue on [GitHub](https://github.com/Septh/WoW-Broker_Cash), where the projet lives.


## Change Log

* Version 1.1.0 - 10-21/2016
	* Also show wealth variation per realm
* Version 1.0.3 - 10-21/2016
	* Use `BreakUpLargeNumbers()` for a nicer main LDB text
	* Updated Readme.md
* Version 1.0.2 - 10/20/2016
	* Fix Lua errors when connecting a char for the first time
* Version 1.0.1 - 10/17/2016
	* Highlight LDB frame on show tooltip
* Version 1.0.0
	* Initial release


## Licence

Broker: Cash is released under the [MIT licence](https://opensource.org/licenses/MIT).


## Enjoy!

Also check my other addons: [BagMeters](https://www.curse.com/addons/wow/bagmeters), [BankItems_MailWatch](https://www.curse.com/addons/wow/bankitems_mailwatch) and [2048 for WoW](https://www.curse.com/addons/wow/wow2048).

If you are an addon developer, also check my [WoW Bundle for vscode](https://marketplace.visualstudio.com/items?itemName=Septh.wow-bundle) extension which brings better Lua language support and WoW API highlighting to Microsoft Visual Studio Code.

-- Septh
