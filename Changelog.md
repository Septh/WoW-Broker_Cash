## Change Log

* Version 2.0.0-beta
	* New: Refactored the code to use a more efficient, timer-based strategy to reset the stats at the correct periods boundaries
	* New: The **Session** stat is now preserved after a UI Reload
	* Several micro-optimizations
* Version 1.4.4 - 2017/12/17
	* Added German locale, thanks to [**Scarwolf**](https://github.com/Septh/WoW-Broker_Cash/pull/2)
* Version 1.4.3 - 2017/12/12
	* Fixed the addon not working on fresh installs (\*sigh\*). [Thanks to **kkrzyzak** for pointing out](https://github.com/Septh/WoW-Broker_Cash/issues/1)
* Version 1.4.2 - 2017/12/12
	* Minor fixes. Weekly stat should reset correctly now
* Version 1.4.1 - 2017/12/04
	* Some more internal optimizations
	* Corrected a flaw in the stats reset logic. Should work as expected now
* Version 1.4.0 - 2017/11/12
	* Some internal optimizations
	* Consolidated the **Show Copper** and **Show Silver** options into a single **Show Silver and Copper** option
	* Added an option to disable the secondary (aka. details) tooltip
	* Added an **Ever** statistic that will never be reset
* Version 1.3.3 - 2017/09/21
	* Toc update for 7.3
	* Using the latest Ace3 files (r1166)
* Version 1.3.2 - 2017/04/05
	* Fixed a stupid bug that prevented the display of copper and silver amounts in sub-tooltip
	* Removed an unwanted global
* Version 1.3.1 - 2017/03/29
	* Toc update for 7.2
	* Fixed a bug that occured when a char spent all his money
* Version 1.3.0 - 2016/12/11
	* Added options to hide copper and silver amounts in both the LDB display and the dropdown menu
* Version 1.2.1 - 2016/11/03
	* Don't highlight the LDB frame if the display is Bazooka
	* Forgot to localize the dialog buttons
* Version 1.2.0 - 2016/11/02
	* Added the ability to reset or delete a character's stats
* Version 1.1.0 - 2016/10/26
	* Toc update for 7.1
* Version 1.1.0 - 2016/10/21
	* Also show wealth variation per realm
* Version 1.0.3 - 2016/10/21
	* Use `BreakUpLargeNumbers()` for a nicer main LDB text
* Version 1.0.2 - 2016/10/20
	* Fix Lua errors when connecting a char for the first time
* Version 1.0.1 - 2016/10/17
	* Highlight LDB frame on tooltip show
* Version 1.0.0
	* Initial release
