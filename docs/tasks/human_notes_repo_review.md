# Bugs

- Tapping on favorite button on listing is not working
- Detail sometimes is having issues with the playing button
- Going back inside a podcast, keeps the podcast being played
- iTunes duration is not well parsed sometimes getting hh:mm, mm
- Detail Page built every change on the podcast
- Subscribing into a new podcast, when going back, library is not being update
- Search doesnt have a debounce when searching
  - Every keystroke hits iTunes (`l`, `le`, `ley` , `leye` → 4 requests)
  - Out-of-order responses: a slow older search overwrites newer results
  - Clearing the field while a search is in flight shows the stale results again
- Search keeps a stale `errorMessage` after a successful retry, same bug as show_detail (`SearchState.copyWith` uses `??`)
- Missing docs across the app
- Library item tap not sending to podcast detail.
- Missing on retry for search podcast + clear button on search (UX), parsing still happening but never shown.
- When an error occurs on the state, copyWith also copies the last state error, meaning, we do not have a parameter for clearError for example.
- Remove .g.dart 


# Improvements

- Use wildcards for unused parameters
- With the newest dart version we can reference private parameteres like: required FavouritesRepository this._favouritesRepository,
- Los podcasts no son paginados?, que pasa si favoritos tienen 100+?
- We're using SharedPreferences without a wrapper, meaning changing to another package would need to change each direct declaration
- artworkUrl checks null but never empty or non valid URL's
- Shouldn't we use the bloc concurrency?
- UI elemnts when a podcast doesnt have episodes


# Architectural questions

- Why feature Services are globally injected comapred to prefs, api client, that are "agnostic" to features?
- Why CabinaApp is stateful?
- What's under the decision of having each route on the pages, and not inside a common "feature" for router?
- DiscoverCubit contains 2 features (library & Discovery), why is it call DiscoverCubit?
- Why we ignore the unawaited on _favouritesRepository.save?
- Should we have views per category? Views, Details, we have mixed detail views and listing views


# AI Founded
- Error Range -> CabinaError
- Sorting by dates
- Architectural patterns
- fallback on error