# Virtual Tourist
Virtual Tourist is a Udacity iOS project app that downloads and stores images from Flickr. The app will allow users to drop pins on a map, as if they were stops on a tour. Users will then be able to download pictures for the location and persist both the pictures, and the association of the pictures with the pin.

For more information, please visit the [project specification page](https://docs.google.com/document/d/1j-UIi1jJGuNWKoEjEk09wwYf4ebefnwcVrUYbiHh1MI/pub?embedded=true).

## Using this app
To use this app, you need to have Xcode 11 installed on your macOS. You also need to request an API key from [Flickr](https://www.flickr.com/). Simply open the project file and replace **Secrets.apiKey** in
```
static let apiKey = Secrets.apiKey
```
at the top of the class definition in FlickrClient.swift with your own API key and run this app on either an emulator or a real device.
