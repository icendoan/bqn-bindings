libc ← •Import "c.bqn"
path ← "/usr/lib64/libcurl.so"

# Corresponds to the CURLoptions enum
options ⇐ {
  # there are *many* missing here, but this gets the job done right now
  verbose ⇐ 41
  write_data ⇐ 10001
  url ⇐ 10002
}

Get ⇐ {
𝕊 url:
 ("/tmp/bqn-curl-" ∾ (∾ •Fmt¨ | •Hash url) ∾ •Fmt •UnixTime @) 𝕊 url;

file 𝕊 url:
 #handle ← ffi.Curl_Easy_Init @
 ffi.Curl_Easy_Setopt_Str ⟨handle, options.url, url ∾ @⟩
 file_ptr ← libc.FOpen ⟨file ∾ @, "w+" ∾ @⟩
 ffi.Curl_Easy_Setopt_Ptr ⟨handle, options. write_data, file_ptr⟩
 ffi.Curl_Easy_Perform handle
 #ffi.Curl_Easy_Cleanup handle
 libc.FClose file_ptr
 •file.Chars file
}

# The raw FFI calls, bound to their C name
ffi ⇐ {
  # common types
  opaque_ptr ← "*:i8"
  string ← "*u8:c8"

  curl_easy_init ⇐ path •FFI ⟨opaque_ptr, "curl_easy_init"⟩

  # the curl_easy_setopt function uses varargs, so overload the common types here
  curl_easy_setopt_int ⇐ path •FFI ⟨"i32", "curl_easy_setopt", opaque_ptr, "i32", "i32"⟩
  curl_easy_setopt_str ⇐ path •FFI ⟨"i32", "curl_easy_setopt", opaque_ptr, "i32", string⟩
  # For use with string pointers, like that from curl_easy_escape
  curl_easy_setopt_ptr ⇐ path •FFI ⟨"i32", "curl_easy_setopt", opaque_ptr, "i32", opaque_ptr⟩
  curl_easy_setopt_long ⇐ path •FFI ⟨"i32", "curl_easy_setopt", opaque_ptr, "i32", "u64"⟩

  curl_easy_perform ⇐ path •FFI ⟨"i32", "curl_easy_perform", '>' ∾ opaque_ptr⟩

  curl_easy_cleanup ⇐ path •FFI ⟨"", "curl_easy_cleanup", '>' ∾ opaque_ptr⟩

  curl_easy_escape ⇐ path •FFI ⟨opaque_ptr, "curl_easy_escape", opaque_ptr, string, "i32"⟩

  curl_free ⇐ path •FFI ⟨"", "curl_free", '>' ∾ opaque_ptr⟩
}

handle ⇐ ffi.Curl_Easy_Init @
