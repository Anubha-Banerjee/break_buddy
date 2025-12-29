'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "955bcf42c86b0e908dc3075a05bacd02",
"assets/AssetManifest.bin.json": "3902536ca942d6c33d4cef894f33abfb",
"assets/AssetManifest.json": "407aa290b5e0f4c089bb52b55bcccaef",
"assets/assets/thumbnails/bent_rows.jpg": "8cfd1d069a2833110a81f863490381c5",
"assets/assets/thumbnails/bird_dog.jpg": "e4105caeb4c3ac5eb154ef92886c134e",
"assets/assets/thumbnails/boat_hold_bicycle.jpg": "51c5a109b1e2d9f06b85097ac634a29e",
"assets/assets/thumbnails/breathing.jpg": "79c6fbe1a5654a91af5780d6b3f72673",
"assets/assets/thumbnails/butt_kicks.jpg": "481c54a3be90dedeac843efb14c826d9",
"assets/assets/thumbnails/cat_cow.jpg": "40d6e5e0aeaeda874bbb8268f5fea792",
"assets/assets/thumbnails/child_pose.jpg": "12bfa1f63faf600f388c4c8401f65cb6",
"assets/assets/thumbnails/cobra_pose.jpg": "89535eeb96dbdc5804b174666df0ff59",
"assets/assets/thumbnails/crush_hold_knee_raise.jpg": "018f5dd53d4f64c0d9663bc62aea2cdd",
"assets/assets/thumbnails/front_kicks.jpg": "10fd9db7252ba25f2c595419ef24d40a",
"assets/assets/thumbnails/glute_bridge_march.jpg": "939818850c1235499b6bf6477268a133",
"assets/assets/thumbnails/high_knees.jpg": "df21fa8cbcfee2281f4259693d3e1f8e",
"assets/assets/thumbnails/high_plank_leg_raise.jpg": "7b89da06e024f0a5b4d6f142b3d4685b",
"assets/assets/thumbnails/hip_raises.jpg": "fe07eef392ccbc7ad61506b1d744ce8e",
"assets/assets/thumbnails/jumping.jpg": "f333aa1530f99ab3a30d93244d3f60db",
"assets/assets/thumbnails/lunge_simple.jpg": "f50a650ae2e18bab26236946a8a58d85",
"assets/assets/thumbnails/nature.jpg": "30b5727f8fbaedd8c7e4e353523b088c",
"assets/assets/thumbnails/punching.jpg": "cc645253274cda989bda8f2194a580b2",
"assets/assets/thumbnails/pushups.jpg": "89258a66a6bbcaa1b95337537e15a426",
"assets/assets/thumbnails/shoulder_exercise.jpg": "8ca9c1916eabbbdf62e48d21485a7265",
"assets/assets/thumbnails/shoulder_raise.jpg": "d3eaeaae16a88758958e626b7a2ea71d",
"assets/assets/thumbnails/side_leg_raises.jpg": "c87fc0e3604576fcb310ee6cd4ed4ce5",
"assets/assets/thumbnails/side_lifts.jpg": "fed2464e6ca8668599b5e0b1d8a406a6",
"assets/assets/thumbnails/side_rows.jpg": "0e8147307f654ff4fc9eca7daaf7a3bf",
"assets/assets/thumbnails/spine_rotation.jpg": "1077284295827dc3b11d096ef1fce979",
"assets/assets/thumbnails/squats.jpg": "b15acab91ba25dad83cf925dc2ed4304",
"assets/assets/thumbnails/squats_sumo.jpg": "80e1a99eebf164fa2463cd57ed56d9b2",
"assets/assets/thumbnails/squat_simple.jpg": "e1d57073e64bc7f01b5d3b55288e3ea9",
"assets/assets/thumbnails/stretch_minute.jpg": "c9507c320de10d50218bb8f67ca53dee",
"assets/assets/thumbnails/stretch_minute_2.jpg": "66992af876e8200b9a6f9f9e73883c0d",
"assets/assets/thumbnails/stretch_minute_3.jpg": "02e3faa0cbe30e29e1fe1972f78cf19c",
"assets/assets/thumbnails/tricep_extension.jpg": "5668fcf7201ab3bce5bc077359dee54d",
"assets/assets/thumbnails/walking.jpg": "d6539414b6e850635470190936908463",
"assets/assets/videos/bent_rows.mp4": "f0e24cb892104b8e50eb4b0f30bdc753",
"assets/assets/videos/bird_dog.mp4": "cec63a35ca7daf0dd54f75e1c176b3de",
"assets/assets/videos/boat_hold_bicycle.mp4": "8a2918e525649bd1d9ccd04cc554c68b",
"assets/assets/videos/breathing.mp4": "1cd43c8d4ea1470eb7a6be8712e66a4d",
"assets/assets/videos/butt_kicks.mp4": "82e210eb0c04b776f94dc6e35540e2e3",
"assets/assets/videos/cat_cow.mp4": "af2b1643da718e261542995840b9e85d",
"assets/assets/videos/child_pose.mp4": "3c4634503bf58c44fb430037672c7eef",
"assets/assets/videos/cobra_pose.mp4": "62757bc7f3ca7711c66ecfb534862dca",
"assets/assets/videos/crush_hold_knee_raise.mp4": "36fc0db9a2c5e8ef6f157f3b620f4431",
"assets/assets/videos/front_kicks.mp4": "fa326b53c6635407ed24d4416070abed",
"assets/assets/videos/glute_bridge_march.mp4": "0e1131ec4a8e5aadb6f597a147501cd8",
"assets/assets/videos/high_knees.mp4": "a587ef3598cceeff513e9fb7c2d0a584",
"assets/assets/videos/high_plank_leg_raise.mp4": "38ad3357646a5ab543eb37514e0b568e",
"assets/assets/videos/hip_raises.mp4": "e488ec44605f6631950ead9771c54bb2",
"assets/assets/videos/jumping.mp4": "3a6cdfbf20a5022c678a70d2275c0f6d",
"assets/assets/videos/lunge_simple.mp4": "9b1d3e9c0a427e197426348353821f00",
"assets/assets/videos/nature.mp4": "a2c2db7febd9ea20163cc6b182f7862b",
"assets/assets/videos/punching.mp4": "696093a4dbced75493d5cf3012d898f3",
"assets/assets/videos/pushups.mp4": "cd4e51d1b3ef0b78cc9ddd90a6ba2621",
"assets/assets/videos/shoulder_exercise.mp4": "e4619384a7729e88b614893f5bb8a306",
"assets/assets/videos/shoulder_raise.mp4": "b926dc5e1ffc576089710cc448516473",
"assets/assets/videos/side_leg_raises.mp4": "0ee081739535a68363c8fd455d6024ef",
"assets/assets/videos/side_lifts.mp4": "97e8c43b31ad7871f3fee4ea264fffa8",
"assets/assets/videos/side_rows.mp4": "092f8b3af9a586b9b07b536c2eb74e8e",
"assets/assets/videos/spine_rotation.mp4": "a4b24ead59d636174070a97e5b58c5a6",
"assets/assets/videos/squats.mp4": "b43defbfbdd8779cd6cd75d484a0fceb",
"assets/assets/videos/squats_sumo.mp4": "71bde8e75d9fed8f5754f8bcc2786391",
"assets/assets/videos/squat_simple.mp4": "95dfec1d52ce6848eb1e488d161f293c",
"assets/assets/videos/stretch_minute.mp4": "cef13bcfacf038328f6fbab81b9bc76f",
"assets/assets/videos/stretch_minute_2.mp4": "f06fefbb7a995643a20fa67984d20c49",
"assets/assets/videos/stretch_minute_3.mp4": "93e3d013f8c38b64edd6932000f84424",
"assets/assets/videos/tricep_extension.mp4": "bd4683bcfff545f9b952a1b9b07b1070",
"assets/assets/videos/walking.mp4": "ace03591faed1e67bfc896331640f747",
"assets/assets/video_config.json": "2501f4b78fbbab836a4da068f4dc578d",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "2f7097cf12a3ed7fa3848fcdd10135e4",
"assets/NOTICES": "b81e7bf0c22b130508f13d148f181e7e",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/media_kit/assets/web/hls1.4.10.js": "bd60e2701c42b6bf2c339dcf5d495865",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "532b1a933e03e2f73a2777372a6e5ced",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "fbe3cd614ffa969c36e69774ea7f5d93",
"/": "fbe3cd614ffa969c36e69774ea7f5d93",
"main.dart.js": "37a65730a89f06f8640ba563326ced4d",
"manifest.json": "da0b0c9c453aa7d1dfd9b2b5a6609d00",
"version.json": "411d89f72d8bd297ccc1807d929d4b80"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
