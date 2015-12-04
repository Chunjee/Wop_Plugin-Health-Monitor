<h1 align="center">
	<img src="http://i.imgur.com/SIHcdDf.png" alt="Plugin-Health-Monitor">
</h1>

### Overview
This tool accepts different plugins to monitor different aspects of TVG's systems.

The current plugins are:
DVR - Monitors DVR APIs
Sites - Monitors HTML status of different sites
SVC - Monitors if SVCs are responding or not

### Example Use
Left on 24/7 and visually alerts WagerOps of any potential problems or statuses.
Settings
check \Plugins folder for settings.
Warnings & Troubleshooting
none
Dev Brief
Browses page or API
Current Status is recorded to memory/object
Object is examined for predefined Online/Offline/Maintenance Page Status
GUI is updated for that object


### Plugins
All plugins check once per min
DVR
DVRs report an error every so often. The error cause is not available via the API.
Usage is what the API is reporting. I don't know why it says 0% 

### Sites
because of the 301,302,305?,307 redirects being used on various sites. Download the entire DOM and check validity.

### Sites2
Original quick check of page HTML.

### Speed
basically just a simple ping after determining the IP address.
IP adress is what the url resolved to
Delay is in milliseconds.

### Speed
Queries user defined services on user defined machines for Running, Stopped, Stop Pend, or Start Pend.

### SVC - DERECIATED
Same as Sites2 but smaller boxes and only checks SVCs status.


|Color Coding: | Color	Meaning |
| ------------- | ----------- |
| ███ Green | Normal Operation |
| ███ Red	| Offline / Requires Attention |
| ███ Orange |	Not Normal Operation / Maintenance Page |
| ███ White |	Check Unsuccessful / Unknown Status |

Technical Details
Latest version is 0.7.2 (12.03.15)
