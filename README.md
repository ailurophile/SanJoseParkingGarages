# SanJoseParkingGarages

The San Jose Parking Garages app downloads parking space availability data from the city of San Jose for the city-owned garages downtown allowing users to see their location relative to the various entrances of the selected garage and use Apple Maps for directions if so desired.  If the data stored in memory is older than 15 minutes when the app is loaded it will show ?? instead of a number in the spaces available column until fresh data is available from the network.  If a garage is closed, the word closed will appear in the spaces available column.  There is also a location notepad which the user can use to store a reminder about where the car is parked for retrieval later.

## Navigation

### Garages View

* Pinch or open two fingers on the map to zoom out or in on the garage locations.
* Tap a pin on the map to see the name of the garage.
* Tap a garage name either in the table or by its pin on the map to go to the directions view.
* Tap the Location Notepad button to go to the text view screen.
* Tap the Refresh button to update the availability data in the table.

### Text View

* Tap inside text box to type in a reminder of where the car is parked.
* Tap Save button to store the contents of the text box in memory.
* Tap outside of text box to dismiss keyboard.
* Select desired text box behavior via switch. Selecting Edit text will cause the contents of the box to remain on screen when the box is touched so the user can make edits.  Selecting Replace will cause the text box to clear when touched so that an entirely new note can easily be entered.  This selection is stored so the desired behavior will be the default the next time this view is active.

### Directions View

* Pinch or open two fingers to zoom out or in on selected garage entrances and user location if Location Services allowed for the app.
* Tap Update location button to move user pin (shown in blue on map) to the current location.  Continuous updating is not active to reduce battery drain.
* Tap pin of desired garage entrance to use Apple Maps for driving directions.
