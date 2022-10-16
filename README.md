# bqn-bindings
Some miscellaneous bindings for useful C libraries from BQN

# cURL - network protocols
A set of bindings for the easy api from [libcurl](https://curl.se/libcurl/).

Currently very barebones, and only the required options for HTTP(S) GET is implemented, using default values for effectively everything.
Example:
```
curl ← •Import "bqn-bindings/curl.bqn" 
html ← "./page.html" curl.Get "https://curl.haxx.se" # writes the html to "./page.html" and returns it to the caller
```

# Jansson - JSON parsing and manipulation
A set of bindings for [jansson](https://github.com/akheron/jansson), which can parse, write, and manipulate JSON.
There is a small API wrapping the libjansson C api, see the method comments in `json.bqn` for more details.

I've currently only used it for parsing JSON (handily just downloaded via curl...), so the facility for writing or mutating JSON objects
is as-yet untested.

Example:
```
 json ← •Import "bqn-bindings/json.bqn"
 object ← json.Parse "{ ""a"": [1, 2, 3], ""b"": [""foo"", ""bar"", ""baz""]}"
{obj‿rawtype‿typeof‿value‿readarray‿readstring‿readobject‿get‿set‿append‿keys‿values‿copy‿deepcopy‿destroy⇐}
   object.TypeOf @
"object"
   object.Keys @
⟨ "a" "b" ⟩
   a ← object.Get "a"
{obj‿rawtype‿typeof‿value‿readarray‿readstring‿readobject‿get‿set‿append‿keys‿values‿copy‿deepcopy‿destroy⇐}
   a.Value @
⟨ 1 2 3 ⟩
   object.Value @
┌─
╵ "a" ⟨ 1 2 3 ⟩
  "b" ⟨ "foo" "bar" "baz" ⟩
                            ┘
 json.QuickParse "{ ""a"": [1, 2, 3], ""b"": [""foo"", ""bar"", ""baz""]}"
┌─
╵ "a" ⟨ 1 2 3 ⟩
  "b" ⟨ "foo" "bar" "baz" ⟩
                            ┘
```

