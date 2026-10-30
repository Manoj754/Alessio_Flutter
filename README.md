# Alessio_Flutter

A Flutter shopping app built against the public [DummyJSON](https://dummyjson.com) API. It covers:

- **Login** (`POST /auth/login`) with the session token stored **securely** and refreshed automatically.
- **Product list** (`GET /products`) with loading, error and empty states, **pull-to-refresh**, **infinite-scroll pagination** and **search**.
- **Product detail** page opened by tapping a product.

It's built with **Riverpod** for state management and a **feature-first MVVM** architecture.

---

## Table of contents

1. [Getting started](#getting-started)
2. [Tech stack](#tech-stack)
3. [Architecture](#architecture)
4. [Folder structure](#folder-structure)
5. [API reference](#api-reference)
6. [Authentication and token handling](#authentication-and-token-handling)
7. [Navigation](#navigation)
8. [State management (Riverpod)](#state-management-riverpod)
9. [Features in detail](#features-in-detail)
10. [Error handling](#error-handling)
11. [Image loading and performance](#image-loading-and-performance)
12. [Design system](#design-system)
13. [Testing](#testing)
14. [Responsive layout](#responsive-layout)
15. [Platform configuration](#platform-configuration)
16. [Known limitations and notes](#known-limitations-and-notes)
17. [How to add a new feature](#how-to-add-a-new-feature)

---

## Getting started

### Requirements
- Flutter **3.47+** (Dart SDK `^3.13.5`), stable channel
- Xcode (for iOS) and/or Android Studio (for Android)

### Run

```bash
flutter pub get
flutter run
```

### Test accounts
Any DummyJSON user can log in. There are 208 of them at <https://dummyjson.com/users>. Most passwords follow the pattern *username + "pass"*:

| Username | Password |
|---|---|
| `emilys` | `emilyspass` |
| `michaelw` | `michaelwpass` |
| `sophiab` | `sophiabpass` |

### Checks

```bash
flutter analyze
flutter test
```

---

## Tech stack

| Package | Version | Why it's used |
|---|---|---|
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | ^2.6.1 | State management and dependency injection |
| [`go_router`](https://pub.dev/packages/go_router) | ^18.1.2 | Declarative routing, with redirects driven by the login state |
| [`http`](https://pub.dev/packages/http) | ^1.6.0 | HTTP client (wrapped by our own `ApiClient`) |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | ^11.2.0 | Stores tokens in the iOS Keychain / Android Keystore |
| [`cached_network_image`](https://pub.dev/packages/cached_network_image) | ^4.0.6 | Disk and memory cache for product images |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | ^9.0.0 | Plus Jakarta Sans typeface |

---

## Architecture

The app is **feature-first MVVM**. Every feature has its own folder, split into four layers:

```
 VIEW (widgets)            draws the screen, forwards user actions
   │   ref.watch / ref.read
 VIEWMODEL (Riverpod)      holds screen state and logic
   │
 SERVICE (repository)      knows API paths, turns JSON into models
   │
 CORE (ApiClient, TokenStorage)   HTTP, tokens, errors — shared by all features
   │
 DummyJSON API
```

**Rules the code follows:**
- **Views never call the API**, and repositories never touch widgets.
- **Only `ApiClient` makes HTTP calls**, and only `ApiClient` and `TokenStorage` touch tokens.
- **Screens never navigate after login or logout.** The router redirects based on the auth state (see [Navigation](#navigation)).
- **No hard-coded colours, text styles or user-facing strings in widgets.** They come from `AppColors`, `AppTextStyles` and `AppStrings`.
- **Errors shown to users are always friendly messages** (`ApiException.message`), never raw server responses.

---

## Folder structure

```
lib/
├── main.dart                         app entry: portrait lock, ProviderScope, MaterialApp.router
├── core/                             shared by every feature
│   ├── config/api_config.dart        base URL, endpoints, page size, timeouts, token lifetime
│   ├── localization/app_strings.dart all user-facing text
│   ├── network/api_client.dart       the only HTTP code: headers, timeout, 401 → refresh → retry
│   ├── network/api_exception.dart    error types (network, timeout, unauthorized…) with friendly messages
│   ├── router/app_router.dart        routes and the login redirect
│   ├── storage/token_storage.dart    tokens in secure storage (+ in-memory cache)
│   ├── util/
│   │   ├── app_colors.dart           colour tokens
│   │   ├── app_text_style.dart       type scale (cached Google Fonts styles)
│   │   ├── app_theme.dart            Material 3 theme
│   │   ├── formatters.dart           price, date, initials
│   │   └── validators.dart           form validators
│   └── widgets/                      reusable UI
│       ├── app_icon_button.dart      round floating icon button (back)
│       ├── app_network_image.dart    cached image, prefetch, flicker-free swap
│       ├── app_snackbar.dart
│       ├── app_state_view.dart       empty / error screen with action
│       ├── app_text_field.dart       labelled filled input with validation
│       ├── brand_mark.dart           logo
│       ├── primary_button.dart       filled / outlined, with loading state
│       └── skeleton_loader.dart      pulsing placeholder block
└── features/
    ├── splash/view/splash_screen.dart
    ├── auth/
    │   ├── model/       auth_user.dart, auth_state.dart
    │   ├── service/     auth_repository.dart
    │   ├── viewmodel/   auth_controller.dart (session), login_controller.dart (form)
    │   └── view/        login_screen.dart, account_sheet.dart, user_avatar.dart
    └── products/
        ├── model/       product.dart, product_review.dart, product_page.dart
        ├── service/     product_repository.dart
        ├── viewmodel/   product_list_controller.dart, product_search_controller.dart,
        │                product_detail_controller.dart
        └── view/        product_list_screen.dart, product_card.dart, product_search_bar.dart,
                         product_detail_screen.dart, product_gallery.dart, product_badges.dart
test/
├── core/network/api_client_test.dart
└── features/products/
    ├── product_list_controller_test.dart
    └── product_search_controller_test.dart
```

---

## API reference

Base URL: `https://dummyjson.com`. All paths are defined in [`api_config.dart`](lib/core/config/api_config.dart).

| Endpoint | Sends token | Used by | Request | Response used |
|---|---|---|---|---|
| `POST /auth/login` | No | `AuthRepository.login` | `{username, password, expiresInMins: 60}` | `accessToken`, `refreshToken`, user fields |
| `GET /auth/me` | Yes | `AuthRepository.restore` | (none) | user fields |
| `POST /auth/refresh` | No (token in body) | `ApiClient` | `{refreshToken, expiresInMins: 60}` | new `accessToken` and `refreshToken` |
| `GET /products?skip=&limit=20` | Yes* | `ProductRepository.fetchPage` | `skip`, `limit` | `{products, total, skip, limit}` |
| `GET /products/search?q=&skip=&limit=20` | Yes* | `ProductRepository.fetchPage(query:)` | `q`, `skip`, `limit` | same shape as above |
| `GET /products/{id}` | Yes* | `ProductRepository.fetchById` | (none) | one full product |

\* The token is sent, but DummyJSON's `/products` endpoints are public and ignore it (see [Known limitations](#known-limitations-and-notes)).

**DummyJSON behaviour the code handles:**
- A wrong password returns **400** (not 401). This is mapped to "That username and password don't match."
- An expired access token returns **401** `"Token Expired!"` on `/auth/*` endpoints.
- A rejected refresh token returns **403**.
- Requests are rate-limited (`x-ratelimit-limit: 100`).

---

## Authentication and token handling

### Login
1. [`LoginScreen`](lib/features/auth/view/login_screen.dart) validates the form, then calls `LoginController.submit()`.
2. [`LoginController`](lib/features/auth/viewmodel/login_controller.dart) tracks the form's state (idle, submitting, or failed with a message) and calls `AuthController.login()`.
3. [`AuthRepository.login`](lib/features/auth/service/auth_repository.dart) posts the credentials and saves **both tokens** in [`TokenStorage`](lib/core/storage/token_storage.dart).
4. `AuthController` sets the state to `authenticated(user)`, and the router redirects to `/products`.

### Secure storage
- Tokens are stored with `flutter_secure_storage`: the **Keychain** on iOS and **Keystore-backed** storage on Android. They are **never** stored in SharedPreferences, which is plain text on disk.
- The access token is also cached in memory, so API calls don't wait on a slow platform-channel read.
- A corrupted keystore entry (possible after an Android backup restore) is treated as "no session" instead of crashing.

### Session restore on launch
`AuthController.build()` returns `unknown`, so the splash screen shows, while `_restore()` runs:

| Situation | Result |
|---|---|
| No token saved | `unauthenticated` → login screen |
| Token valid (`GET /auth/me` succeeds) | `authenticated(user)` → products |
| Token expired, refresh succeeds | refreshed silently → products |
| Refresh token rejected by the server | tokens cleared → login screen |
| Offline / server unreachable | `authenticated(null)`: the user stays signed in, and the products screen shows its own offline state with retry |

### Automatic token refresh
The access token lasts **60 minutes** and the refresh token **30 days**. Refresh happens **on demand, not on a timer**:

1. An authorized request comes back **401**.
2. `ApiClient` calls `POST /auth/refresh` **once**. If several requests fail at the same moment, they share a single refresh call.
3. **Success:** the new tokens are saved and the original request is retried. The user doesn't notice anything.
4. **Server rejects the refresh** (4xx): the tokens are cleared, `sessionExpired` fires, and `AuthController` logs the user out.
5. **Refresh can't complete** (offline, timeout, 5xx): the tokens are kept, the user is **not** logged out, and the screen shows the real error. The next request tries again.

### Logout
The avatar opens the **account sheet** → *Log out* → `AuthController.logout()` clears the tokens and sets `unauthenticated` → the router goes to `/login`. DummyJSON has no logout endpoint.

---

## Navigation

Defined in [`app_router.dart`](lib/core/router/app_router.dart) with `go_router`.

| Route | Screen |
|---|---|
| `/` | `SplashScreen` |
| `/login` | `LoginScreen` |
| `/products` | `ProductListScreen` |
| `/products/:id` | `ProductDetailScreen` (nested, so the back button works) |

**How the redirect works**
- `routerProvider` mirrors `authControllerProvider` into a `ValueNotifier` that is used as `refreshListenable`. Any login, logout or session expiry re-runs the redirect.

| Auth status | Where the user goes |
|---|---|
| `unknown` | stays on `/` (splash) |
| `unauthenticated` | `/login` |
| `authenticated` | `/products` if on splash or login; otherwise stays where they are |

**Opening a product:** `context.push('/products/12', extra: product)`.
- The tapped product is passed as `extra`, so the detail page draws instantly.
- When opened from a deep link there's no `extra`, so the page loads from the API.

---

## State management (Riverpod)

### Providers

| Provider | Riverpod type | Holds | Lifetime |
|---|---|---|---|
| `tokenStorageProvider` | `Provider` | `TokenStorage` | app |
| `apiClientProvider` | `Provider` | `ApiClient` (closed on dispose) | app |
| `authRepositoryProvider`, `productRepositoryProvider` | `Provider` | repositories | app |
| `authControllerProvider` | `NotifierProvider` | `AuthState` (session) | app; the router listens to it |
| `loginControllerProvider` | `AutoDisposeNotifierProvider` | `AsyncValue<void>` (form submit state) | login screen |
| `productSearchProvider` | `AutoDisposeNotifierProvider` | current search query (with debounce) | product list screen |
| `productListControllerProvider(query)` | `AsyncNotifierProvider.autoDispose.family` | `ProductListState` per query | while shown |
| `productDetailProvider(id)` | `FutureProvider.autoDispose.family` | one `Product` | detail page |
| `routerProvider` | `Provider` | `GoRouter` | app |

How they depend on each other:

```
tokenStorageProvider ─► apiClientProvider ─► authRepositoryProvider ─► authControllerProvider ─► routerProvider
                               │                                         ▲
                               │                                         └─ loginControllerProvider
                               └─► productRepositoryProvider ─► productListControllerProvider(query)
                                                              └─► productDetailProvider(id)
productSearchProvider ─► (selects which productListControllerProvider(query) the screen watches)
```

### Why Riverpod
1. **`AsyncValue` gives loading, error and data states for free.** That maps directly onto the required loading, error and empty states.
2. **No `BuildContext` needed**, so business logic lives in viewmodels, not widgets. This keeps MVVM clean.
3. **Compile-time safety:** no runtime "provider not found" errors, unlike `provider`.
4. **Easy to test:** any dependency can be replaced with `overrideWithValue`. The tests replace the repository with a fake; no device or network needed.
5. **`autoDispose` and `family`** handle screen-only state and per-query lists without manual cleanup.
6. **Less boilerplate than BLoC** (no event and state classes for every action) while staying just as structured, and **more explicit than GetX**, with no hidden global state.

Riverpod 2.x is used **without code generation** (`Notifier` / `AsyncNotifier` classes written by hand). This keeps the build simple, with no `build_runner` step.

---

## Features in detail

### Login screen
- **Fields:** labelled username and password inputs.
  - Validation runs on submit and re-checks as you type once an error is showing.
  - The password field has a show/hide toggle.
  - Autofill hints work with password managers.
- **While submitting:** the fields are disabled and the button shows a spinner.
- **Failed login:** an inline error banner appears and clears as soon as a field is edited.

### Product list
- **Header:**
  - A greeting with the user's first name, the "Discover" title and the user's initials avatar (which opens the account sheet).
  - Scrolling down hides the greeting and keeps the **search bar pinned**.
  - **Any scroll up brings the header back**, so the profile button is always one small scroll away. This uses a `SliverAppBar` set to `pinned` and `floating`. It is deliberately **not** `snap`: snapping runs when a scroll stops, and tapping the avatar mid-glide stopped the scroll with no direction, which snap treats as "close", so the header hid under the user's finger.
- **Grid:** square product photos, **2 columns on phones and more on tablets** (as many as fit at a minimum card width of 170px).
  - Each card shows a discount badge, rating chip, brand, a two-line title, the price and the original price crossed out.
  - Card height grows with the user's text size, and a long price shrinks slightly instead of wrapping, so nothing gets clipped.
- **Pagination** (`ProductListController.loadMore`):
  - Loads **20 products per page** (`skip`/`limit`) and starts the next page **800px before the end** of the list.
  - Safe to call on every scroll event. It does nothing while loading, when everything is loaded, or after a page failed (it waits for retry).
  - Removes duplicate products by `id`, and adds new items to the *current* list, which matters if a refresh happened while the page was loading.
  - A failed page **keeps the products already on screen** and shows an inline *Try again* at the bottom.
- **Pull-to-refresh:** reloads page 1. If it fails, the existing list stays and a snackbar explains why.
- **Search** (`GET /products/search`):
  - [`ProductSearchController`](lib/features/products/viewmodel/product_search_controller.dart) **waits 350ms after typing stops** before searching, so typing "lipstick" makes 1 request, not 8. The keyboard's search button applies it immediately, and clear cancels any pending search.
  - Each query has its **own list instance** (`productListControllerProvider(query)`), so results, pages and errors never mix between searches.
  - Results show *"23 results for "phone""*. No matches show an empty state with *Clear search*.
  - A new search scrolls back to the top.
- **States:**
  - first load → placeholder cards
  - error → full-screen message with *Try again* (different icon when offline)
  - empty catalogue → empty state
  - no search results → their own empty state

### Product detail
- **Photos:** full-width swipeable gallery with page dots and a `1 / 3` counter, and a floating back button.
- **Summary panel** (white, rounded top):
  - category and brand chips, title, star rating and review count
  - price with the original price crossed out, a discount badge and a green **"You save $X"** line
  - stock status: green *In stock*, amber *Only N left* (fewer than 10), or red *Out of stock*
- **Description** collapses to 4 lines with *Read more* when it's longer.
- **Details:** shipping, warranty and returns, each with an icon. Empty values are hidden.
- **Reviews:** an average-rating summary card, then each review with initials, date, stars and comment.
- **Loading:** the page draws immediately from the tapped list item and swaps to the full record when it arrives. Opened from a deep link, it shows a placeholder layout; on error, a retry screen.

### Account sheet
A bottom sheet with the user's initials, full name, email, `@username` and a *Log out* button.

---

## Error handling

All failures become an [`ApiException`](lib/core/network/api_exception.dart) with a **type** and a **message that's safe to show users**:

| Cause | Type | Message |
|---|---|---|
| No connection (`SocketException`, `ClientException`) | `network` | "You're offline. Check your connection and try again." |
| More than 20 seconds | `timeout` | "This is taking longer than usual…" |
| 401 / 403 | `unauthorized` | "Your session has ended. Please log in again." |
| 404 | `notFound` | "We couldn't find that." |
| 5xx | `server` | "Something went wrong on our side…" |
| Wrong login (400) | `unauthorized` | "That username and password don't match." |

Raw response bodies are only printed to the console in **debug** builds.

---

## Image loading and performance

[`AppNetworkImage`](lib/core/widgets/app_network_image.dart) uses Flutter's `Image` with a `CachedNetworkImageProvider` (disk and memory cache):

- **Prefetch on touch:** a card starts downloading the detail photo on `onTapDown`, about 100ms before the tap completes.
- **Thumbnail placeholder:** the first gallery photo shows the list thumbnail (already in memory) until the full image has decoded.
- **Instant swap, no cross-fade:** the thumbnail and full image swap in one frame. Product photos have transparent backgrounds, so a cross-fade made them visibly blink.
- **Memory hits draw immediately:** if the image is already cached (`wasSynchronouslyLoaded`), it shows on the first frame with no placeholder.
- **Gallery prefetch:** opening the detail page starts downloading every gallery photo, so swiping never waits.
- **Thumbnail prefetch:** each new page's thumbnails (about 5–10 KB each) start downloading as soon as the page arrives, so cards usually have their photo before you scroll to them.
- **Smooth opening animation:** the list photo flies into the detail gallery. Padding sits outside the animated widget, so the photo doesn't jump when the animation starts.
- **Loading and errors:** a small spinner (no grey box) while loading. A failed load falls back to the thumbnail or a quiet icon, never Flutter's red error box.

---

## Design system

**Colours** ([`app_colors.dart`](lib/core/util/app_colors.dart)): a neutral, product-first palette. Every text colour passes WCAG 4.5:1 contrast.

| Token | Value | Use |
|---|---|---|
| `ink` | `#0F1115` | text, prices, buttons, avatar |
| `background` | `#F5F6F8` | page background |
| `surface` | `#FFFFFF` | cards, sheets |
| `imageTile` | `#EEF0F3` | behind product photos |
| `fieldFill` | `#F1F2F5` | inputs, chips |
| `textSecondary` / `textMuted` | `#5B6170` / `#737885` | secondary text |
| `success` | `#15803D` | "You save", in stock |
| `warning` | `#B45309` | low stock |
| `error` / `errorText` | `#DC2626` / `#B91C1C` | errors, out of stock |
| `star` | `#FFB020` | rating stars (icons only) |

**Typography** ([`app_text_style.dart`](lib/core/util/app_text_style.dart)): **Plus Jakarta Sans** throughout.
- Styles: `headline` (800), `title` (700), `cardTitle` (600), `price` (800, tabular figures so digits line up), `body`, `caption`, `label`.
- Each style is **cached** after its first use (keyed by everything except colour), because creating Google Fonts styles inside `build` is relatively expensive.

**Theme** ([`app_theme.dart`](lib/core/util/app_theme.dart)):
- Material 3, with the colour scheme built from the tokens above.
- Themed snackbar, bottom sheet, text selection and progress indicators.
- **iOS-style slide page transitions on both platforms**, so navigation feels the same everywhere and iOS keeps swipe-to-go-back.

**Text:** every user-facing string lives in [`app_strings.dart`](lib/core/localization/app_strings.dart), so moving to `flutter gen-l10n` later doesn't require touching any layouts.

---

## Testing

```bash
flutter test
```

There are **14 unit tests**. None need a device or the network: the repository is faked, or HTTP is mocked with `http/testing.dart`'s `MockClient`.

| File | What it covers |
|---|---|
| [`api_client_test.dart`](test/core/network/api_client_test.dart) | Refresh succeeds → retry. Refresh rejected → logout and tokens cleared. Offline or 5xx during refresh → session kept. Three requests failing with 401 at once share **one** refresh call. |
| [`product_list_controller_test.dart`](test/features/products/product_list_controller_test.dart) | First page loads. `loadMore` until the end with no duplicates. A failed page keeps the items and can be retried. A failed refresh keeps the list. An empty catalogue gives the empty state. The search query reaches every page request. |
| [`product_search_controller_test.dart`](test/features/products/product_search_controller_test.dart) | Typing quickly applies only the final text, once. Submit applies immediately and trims spaces. Clear cancels a pending search. |

---

## Responsive layout

The app is built to work on small phones, large phones and tablets, with the keyboard open or closed, and with large system text sizes.

| Area | How it adapts |
|---|---|
| **Product grid** | Column count comes from the screen width (2 on phones, up to 6 on wide screens). Card height = square photo + a text block scaled with the user's text size. |
| **List header** | The header height is calculated from the text size; the greeting and title are limited to one line each. The search bar has a fixed, text-scaled height, and its slot in the header is calculated from that height, so the two always match. |
| **Login** | Scrolls when the keyboard is open (the focused field scrolls into view, and dragging closes the keyboard). The form is limited to 460px wide on tablets. |
| **Product detail** | Content is limited to 640px wide on tablets. Chips and the rating line wrap onto a second line instead of overflowing. The photo area is capped in height on wide screens. |
| **Empty / error states** | Use `SliverFillRemaining(hasScrollBody: false)`, so they centre in the free space and still scroll when the keyboard reduces the height. |
| **Search keyboard** | Tapping outside the field or dragging the list closes the keyboard. |

---

## Platform configuration

- **Android:** the `INTERNET` permission is declared in `android/app/src/main/AndroidManifest.xml`. Release builds can't reach the network without it.
- **Orientation:** the app is locked to portrait in `main.dart`.
- **Secure storage:** no extra setup needed on iOS or Android.

---

## Known limitations and notes

- **DummyJSON is a free test API.** The data is fake and shared, and requests are rate-limited (about 100 per window). Don't use it in production.
- **`/products` is public.** It ignores the token, so after 60 minutes product calls keep working without triggering a refresh. In practice the token is checked by `/auth/me` at launch. To make products require a valid login, switch the paths in `ApiConfig` to `/auth/products` and `/auth/products/{id}`.
- **A malformed (not expired) token** gets a **500** from `/auth/me` instead of a 401. The app treats it as a server error and keeps the user signed in. This only happens if stored data is corrupted.
- **DummyJSON's user `image` is a generated pattern, not a photo**, so the avatar shows initials instead.
- **Google Fonts are downloaded at runtime** on first launch. To work fully offline from the first launch, bundle the font files as assets.
- **App identifiers** are still the defaults (`com.example.flutterapp`, package name `flutterapp`). Change them before publishing.

---

## How to add a new feature

1. Create `lib/features/<feature>/` with `model/`, `service/`, `viewmodel/` and `view/`.
2. **Model:** a plain immutable class with a defensive `fromJson` (default values for missing fields).
3. **Service:** a repository that takes `ApiClient` and exposes a `Provider`. Add new paths to `ApiConfig`.
4. **ViewModel:** a `Notifier`, `AsyncNotifier` or `FutureProvider`. Use `autoDispose` for screen-only state and `family` for per-id or per-query state.
5. **View:** a `ConsumerWidget` that only renders state and calls viewmodel methods. Use `AppColors`, `AppTextStyles`, `AppStrings` and the `core/widgets`.
6. **Route:** add it to `AppRouter` / `routerProvider`.
7. **Tests:** override the repository provider with a fake and test the viewmodel.
