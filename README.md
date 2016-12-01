# cordova-plugin-file-sync
This plugin does just sync files comparing a `manifest.json` to find out changed files. Then it downloads or deletes changed files.

Currently only IOS is implemented. Feel free to do the Android implementation.

### installation
```sh
// stable
cordova-plugin-add-swift-support
cordova plugin add cordova-plugin-file-sync

// development
cordova plugin add `github repo`
```
In `config.xml` add `<preference name="UseLegacySwiftLanguageVersion" value="true" />`

### Why?
Reasons:
- Since in `WKWebview` you can't go out of the approot and access documents i needed to find another solution.
- I used [cordova-hot-code-push-plugin](https://github.com/nordnet/cordova-hot-code-push/) as `in-app-updater` but there the old and new release are in different directories and you must perform a page refresh to be able to access newly synced images, which I didn't want.

### Usage
#### File Comparing
This plugins compares the `local manifest.json` against the `server manifest.json` to find out, which files changes. This looks like:
```json
[
  {
    "file": "firstfile.png",
    "hash": "e9c7a01993abf06e9080b9216642cabe"
  },
  {
    "file": "deep/path/files/secondfile.jpg",
    "hash": "2c2ae068be3b089e0a5b59abb1831550"
  }
]
```
#### New release
It compares a `local release.json` against a `server release.json` to find out if a new release is available. It just compares the strings of the release property!
```json
{
  "release": "my-version-2"
}
```
#### JS
example call:
```js
cordova.plugins.fileSync.sync({
    pathRelease: 'https://domain.com/whatever/release.json',
    pathManifest: 'https://domain.com/whatever/manifest.json',
    pathRemoteDir: 'https://domain.com/whatever/www/'
    pathLocalDir: 'file:/where/you/want/the/downloads'
},
function(msg) {
    console.log('success', msg);
},
function(err) {
    console.log('error', err);
});
```
explanation of args:
- pathRelease: is the server path where json will be returned which includes a property named "release"
- pathManifest: is the server path where json will be returned which include an arreay of objects with "file" and "hash" properties
- pathRemoteDir: is the server path where the remote files are located
- [pathLocalDir]: is the path on ios where the manifest and all remote files will be stored, the release will be saved elsewhere in something like a native localstorage.

defaults:
```
pathLocal: "/Users/pm/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application/<UDID>/Library/Application Support/cordova-plugin-file-sync/"
```
returns if it worked positiv ingerer in success callback, if error occured negativ integer in error callback:
- 1 no update found
- 0 update installed 
- -1 request to release.json failed
- -2 parsing of release.json failed
- -3 request to manifest.json failed
- -4 parsing of manifest.json failed
- -5 aborted (only possible if app did really quit)
- -6 could not move file to pathLocal
- more todo?
#### Trick
To be more flexible you alway can generate the `serverside json` via `php` or whatever you like to use.

#### chcp (cordova-hot-code-push) and locations
Some filesystem and how to use it with chcp explanations, although you can use it without chcp-plugin.
- On `first startup` with `chcp` plugin you are in:
```
todo
```

- On `sencod startup` with `chcp` plguin you are in:
```
file:///Users/pm/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application/<UDID>/Library/Application Support/<com.company.yourapp>/cordova-plugin-hot-code-push/<chcp-version>/www
```
So since the location will change you should not use relative pathes to get the synced files.
- The synced files will by default be saved to
```
file:///Users/pm/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application/<UDID>/Library/Application Support/cordova-plugin-file-sync/
```
So to create your absolute pathes on js side you could do:
```js
// using cordova-plugin-file
resolveLocalFileSystemURL('cdvfile://localhost/library/Application Support/cordova-plugin-file-sync', function(entry) {
    console.log('library: ' + entry.toURL());
// file:///Users/pm/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Data/Application/<UDID>/Library/Application Support/cordova-plugin-file-sync
});
```
### Todo
Altough there are todo's this plugin is `production ready`, altough I never used it with a app in the appstore apple will may find something that isn't alright so I would be happy about feedback if it worked or not.

Also since it's swift it's a bit more beginner friendly and I'm here for helping you, when you try to contribute.

**Core Features:**
- [x] download files 
- [x] remove files
- [ ] upload files via http -> so you have to make probably a php script to recieve the file (is it possible to save files to  `Application Support folder?`)

**Feature:**
- [ ] Sending progress event (find other plugin to see how / cordova-content-sync-plugin maybe?)
- [ ] something like cronjobs
- [ ] Event / or Function which returns current status of plugin `working`, `finish` or whatever, will be more usefull when there is also something like a cronjob.
- [ ] resume download if you where aborted, due to exit. background doesn't matter, because the download would still go on.
- [ ] ftp implemenation try https://github.com/Constantine-Fry/rebekka
- [ ] webdav implemenation
- [ ] optional comparing `release.json`
- [ ] return more for example: numUploadedFiles, numDownloadedFiles, numDeletedFiles, newVersion,  oldVersion. more ideas?

**Qualtiy:**
- [ ] Error handling in Downloader
- [ ] currently the most errors are just surrounded with if else but not returned
- [ ] migrate to swift 3
- [ ] avoid conflicts with other plugins using for every class a named prefix
- [ ] instead of returning status via int, use enum/constants like [chcp errors](https://github.com/nordnet/cordova-hot-code-push/wiki/Error-codes)
- [ ] what/which code is causing the thread warning of 15ms?

### Feelings and why swift? :P 
Because i had no idea of `Obj-c` but the syntax looked really strange I wanted instead to try out `swift`. For me starting native developmen `swift` had a bit a easier syntax but it seems not so complete and there are less libs available. Also I really hate to use `callback` instead `js like promises`, altough there are libs for that available, I didn't want to use them in such a small project.
