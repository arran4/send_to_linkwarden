# send_to_linkwarden

Android app for sending links to Linkwarden

## Authentication

The app now supports both API key and username/password authentication. When
adding a Linkwarden instance you can choose your preferred method. If you use
username and password, the app will create a temporary session token just like
the official browser extension.

The link form now fetches a small portion of the target page to display a
preview image and pre-fill the title and description when available.

![Screenshot_20240823_155131.png](assets%2FScreenshot_20240823_155131.png)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Web and Browser Extension Support

This app can be built as a standard web application (PWA) or as a browser extension.

When built as a standard web application, it must be served from a secure origin (HTTPS or `localhost`) so that `flutter_secure_storage` can use `window.crypto` APIs.

When packaged as a Chrome or Firefox extension (using `scripts/build_extension.sh`), it will attempt to use the `chrome.tabs.query` or `browser.tabs.query` APIs to pre-fill the currently active tab URL. If permissions are missing or the API is unavailable, it gracefully degrades to standard behavior without crashing.
