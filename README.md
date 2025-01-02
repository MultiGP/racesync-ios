## [<img src="Documentation/Github/racesync_readme_header.jpg">](https://apps.apple.com/us/developer/multigp-inc/id1491110679)

## Screenshots

<table style="border-collapse: collapse; width: auto;">
  <tr>
    <th style="padding: 0; border: 1px solid black;"><img src="Documentation/App Store/Screenshots/RaceSync_6.9_screenshot_0.png" style="display: block; width: auto; height: auto;"></th>
    <th style="padding: 0; border: 1px solid black;"><img src="Documentation/App Store/Screenshots/RaceSync_6.9_screenshot_1.png" style="display: block; width: auto; height: auto;"></th>
    <th style="padding: 0; border: 1px solid black;"><img src="Documentation/App Store/Screenshots/RaceSync_6.9_screenshot_2.png" style="display: block; width: auto; height: auto;"></th>
    <th style="padding: 0; border: 1px solid black;"><img src="Documentation/App Store/Screenshots/RaceSync_6.9_screenshot_3.png" style="display: block; width: auto; height: auto;"></th>
  </tr>
  <tr>
    <th style="padding: 0; border: 1px solid black;"><img src="Documentation/App Store/Screenshots/RaceSync_6.9_screenshot_4.png" style="display: block; width: auto; height: auto;"></th>
    <th style="padding: 0; border: 1px solid black;"><img src="Documentation/App Store/Screenshots/RaceSync_6.9_screenshot_5.png" style="display: block; width: auto; height: auto;"></th>
    <th style="padding: 0; border: 1px solid black;"><img src="Documentation/App Store/Screenshots/RaceSync_6.9_screenshot_6.png" style="display: block; width: auto; height: auto;"></th>
    <th style="padding: 0; border: 1px solid black;"><img src="Documentation/App Store/Screenshots/RaceSync_6.9_screenshot_7.png" style="display: block; width: auto; height: auto;"></th>
  </tr>
</table>

## RaceSync for iOS & WatchOS
Get ready to race with RaceSync, the official app of the MultiGP Drone Racing League.
Find and join local drone races hosted by MultiGP chapters worldwide with a free account.

### Features for racers:
* Discover local races and chapters
* Join races easily and view race information
* Check assigned video frequency during races
* View race participants
* Add races to your calendar and get directions to the venue
* Manage aircraft from your profile
* Use MultiGP QR code for special events and ZippyQ races

### Features for chapter organizers:
* Create, duplicate, and edit races
* Manage pilot participation in races
* Access official MultiGP track designs (GQ, UTT, Champs, and more)
* Submit GQ track measurement validation

Start racing now with RaceSync!

## Public beta is open

[<img src="https://user-images.githubusercontent.com/43776784/125545484-11474758-6313-4ddb-b96a-4a11113b1958.png" width=25%>](https://testflight.apple.com/join/BRXIQJLb)

## Community Contribution

Are you familiar with MultiGP and iOS/Swift development?
Do you have feature ideas or found bugs on the existing production app?
Feel free to create Issues and submit Pull Requests with your feedback!

### Development Setup

* [Download XCode](https://apps.apple.com/ca/app/xcode/id497799835?mt=12).
* Fork and clone this Git repository
* Create a file called `credentials-debug.plist` and place it under `$SRCROOT/../credentials/`
* Generate your chapter API key. [Watch tutorial](https://www.youtube.com/watch?v=O8e9KoRhbHU&t=55s)
* Add `API_KEY` to the plist and insert your Chapter API key (note that this type of API key won't give you full access to the MGP API but it is enough to run and test the app).
* Compile and Run!

## Continuous Integration

The following application targets are being privately built and tested using XCode Cloud:
- [**[RaceSync]**](https://appstoreconnect.apple.com/teams/69a6de89-7661-47e3-e053-5b8c7c11a4d1/apps/1491110680/ci/groups)
- [**[RaceSyncAPI]**](https://appstoreconnect.apple.com/teams/69a6de89-7661-47e3-e053-5b8c7c11a4d1/frameworks/C4E896B0-7561-452A-9008-4410D9F88776/groups)

## Platform

* iOS 14.0+
* WatchOS 7.0+
