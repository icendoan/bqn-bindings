####
# This file contains some bindings for libjansson
# https://github.com/akheron/jansson, a library for reading and
# writing JSON files

# To read a json file, call one of the constructor functions `Read`, `Parse`, or `FromPointer`
# then the fields of the objects can be inspected with `.TypeOf`, `.Keys`, `.Values`, `.Get`, `.Set`
# A common case is to just read the JSON blob as-is, and utility functions `QuickParse` and `QuickRead`
# do this. For more specific information see the function comments.

# Example:
# json ← •Import "json.bqn"
# object ← json.Parse "{ ""a"": [1, 2, 3], ""b"": [""foo"", ""bar"", ""baz""]}"
#{obj‿rawtype‿typeof‿value‿readarray‿readstring‿readobject‿get‿set‿append‿keys‿values‿copy‿deepcopy‿destroy⇐}
#   object.TypeOf @
#"object"
#   object.Keys @
#⟨ "a" "b" ⟩
#   a ← object.Get "a"
#{obj‿rawtype‿typeof‿value‿readarray‿readstring‿readobject‿get‿set‿append‿keys‿values‿copy‿deepcopy‿destroy⇐}
#   a.Value @
#⟨ 1 2 3 ⟩
#   object.Value @
#┌─
#╵ "a" ⟨ 1 2 3 ⟩
#  "b" ⟨ "foo" "bar" "baz" ⟩
#                            ┘
# json.QuickParse "{ ""a"": [1, 2, 3], ""b"": [""foo"", ""bar"", ""baz""]}"
#┌─
#╵ "a" ⟨ 1 2 3 ⟩
#  "b" ⟨ "foo" "bar" "baz" ⟩
#                            ┘

# todo: refcounting, test json creation and mutation

libc ← •Import "c.bqn"
path ← "/usr/lib64/libjansson.so"

# Read the input text as a JSON string, and return its value
# param json: the BQN string containing the full json text
# returns: a BQN value representing the parsed JSON, or @ if it is invalid
QuickParse ⇐ { 𝕊 json:
 obj ← Parse json
 value ← obj.Value @
 obj.Destroy @
 value
}

# Read the file at `path` and return its value
# param path: a string path to a JSON file
# returns: a BQN value representing the contents of the JSON file, or @ if it is invalid
QuickRead ⇐ { 𝕊 path:
 obj ← Read path
 value ← obj.Value @
 obj.Destroy @
 value
}

# Build a JSON namespace wrapping the supplied libjansson handle 
# this is only useful to call if accessing things via the `ffi` namespace directly
# param 𝕩: the i8 array representing the json_t *
# returns: a JSON namespace
FromPointer ⇐ { 𝕊 𝕩:
 obj ⇐ 𝕩

 # The integer value of the type enum
 # 𝕩: ·
 # returns: the integer value of the json_type enum
 RawType ⇐ { 𝕊𝕩: obj ≡ 8⥊0 ? 7 ; ⊑ libc.MakeI32Vec ⟨1, obj⟩ }

 # The type of the JSON object represented by this namespace
 # 𝕩: ·
 # returns: a string representing the type, e.g. "array", "object", or "real"
 TypeOf ⇐  { 𝕊𝕩: (RawType obj) ⊑ ffi.types }

 # Produces the BQN value of this JSON value. If this is an array or object, then it is recursively
 # produced. Atomic types are mapped, as are lists. Objects become rank-2 arrays where on each row
 # the first cell is the key and the second cell is the value.
 # param 𝕩: ·
 # returns: the BQN representation of this JSON value
 Value ⇐ { 𝕊𝕩:
  accessor ← (RawType ⊑ ⟨readObject, readArray, readString, ffi.json_number_value, ffi.json_number_value, 1, 0, @⟩˙) obj
  Accessor obj
 }

 # Reads the JSON value as an array
 # throws if the value is not an array
 ReadArray ⇐ { 𝕊 𝕩:
  "JSON value is not an array" ! "array" ≡ TypeOf @
  n ← ffi.JSON_Array_Size obj
  {𝕊𝕩: o ← FromPointer ffi.JSON_Array_Get ⟨obj, 𝕩⟩ ⋄ o.Value @ }¨ ↕n
 }

 # Reads the JSON value as a string
 # throws if the value is not a string
 ReadString ⇐ { 𝕊𝕩:
  "JSON value is not a string" ! "string" ≡ TypeOf @
  libc.From_CString ffi.JSON_String_Value obj
 }

 # Reads the JSON value as an object
 # throws if the value is not an object
 ReadObject ⇐ { 𝕊𝕩:
  "JSON value is not an object" ! "object" ≡ TypeOf @
  output ← ⟨⟩
  { 𝕊iter:
   key ← libc.From_CString ffi.JSON_Object_Iter_Key iter
   value ← FromPointer ffi.JSON_Object_Iter_Value iter
   output ↩ output ∾ key ⋈ value.Value @
   ffi.JSON_Object_Iter_Next ⟨obj, iter⟩
  } •_while_ {𝕊𝕩: 𝕩 ≢ 8⥊0} ffi.JSON_Object_Iter obj
  ∘‿2 ⥊ output
 }

 Get ⇐ {
  𝕊 key: "array" ≡ TypeOf @ ? FromPointer ffi.JSON_Array_Get ⟨obj, key⟩ ;
  𝕊 key: "object" ≡ TypeOf @ ? FromPointer ffi.JSON_Object_Get ⟨obj, key ∾ @⟩ ;
  !˜ "JSON value was required to be object or array, but found " ∾ TypeOf @ 
 }

 Set ⇐ { 
  key 𝕊 value: "array" ≡ TypeOf @ ? ffi.JSON_Array_Set ⟨obj, key, value⟩ ;
  key 𝕊 value: "object" ≡ TypeOf @ ? ffi.JSON_Object_Set ⟨obj, key ∾ @, value⟩ ;
  !˜ "JSON value was required to be object or array, but found " ∾ TypeOf @
 }

 Append ⇐ { 𝕊value:
  "Can only append to an array" ! "array" ≡ TypeOf @
  ffi.JSON_Array_Append ⟨obj, value⟩
  ffi.JSON_Array_Size obj
 }

 Keys ⇐ { 𝕊𝕩: 
  "JSON value is not an object or an array" ! ⊑ (< TypeOf @) ∊ ⟨"array", "object"⟩
  (TypeOf @) 𝕊 𝕩 ;
 "object" 𝕊 𝕩:
  k ← ⟨⟩
  { 𝕊 iter: k ↩ k ∾ <libc.From_CString ffi.JSON_Object_Iter_Key iter, ffi.JSON_Object_Iter_Next ⟨obj, iter⟩} •_while_ {𝕊𝕩: 𝕩 ≢ 8⥊0} ffi.JSON_Object_Iter obj
  k ;
  "array" 𝕊 𝕩: ↕ ffi.JSON_Array_Size obj ;
  𝕨 𝕊 𝕩: !˜ "JSON value is not an object or an array"
 }

 Values ⇐ {
  𝕊𝕩: (TypeOf @) 𝕊 𝕩;
  "array" 𝕊 𝕩: ReadArray 𝕩 ;
  "object" 𝕊 𝕩:
   v ← ⟨⟩
   { 𝕊 iter: v ↩ v ∾ < (FromPointer ffi.JSON_Object_Iter_Value iter).Value @, ffi.JSON_Object_Iter_Next ⟨obj, iter⟩} •_while_ {𝕊𝕩: 𝕩≢8⥊0} ffi.JSON_Object_Iter obj
   v ;
   𝕨𝕊𝕩: Value @
 }

 Copy ⇐ { 𝕊𝕩: FromPointer ffi.JSON_Copy obj }
 DeepCopy ⇐ { 𝕊x: FromPointer ffi.JSON_Deep_Copy obj }
 Destroy ⇐ {𝕊𝕩:
  obj ≡ 8 ⥊ 0 ? @ ;
  # this can't actually decrement ref counts, since those are macros and not functions to call
  # todo: handle refcounting properly for these objects
  count ← 2 ⊑ libc.MakeI32Vec ⟨3, obj⟩ # probably not more than 2⋆32 references...
  count ≡ 1 ? { ffi.JSON_Delete obj ⋄ obj ↩ 8⥊0 ⋄ @ } ; @
 }
}

Parse ⇐ { 𝕊 text:
  FromPointer ffi.Json_LoadB ⟨text, ≠text, ffi.flags.default, 8⥊0⟩ # todo: error reporting
}

Read ⇐ { 𝕊 path:
 FromPointer ffi.Json_Load_File ⟨path ∾ @, ffi.flags.default, 8⥊0⟩ # todo: error reporting
}

FromString ⇐ { 𝕊𝕩: FromPointer ffi.JSON_StringN ⟨𝕩, ≠𝕩⟩}
FromNumber ⇐ { 𝕊𝕩: FromPointer ffi.JSON_Real 𝕩 }
CreateArray ⇐ { 𝕊𝕩: FromPointer ffi.JSON_Array @ } 
CreateObject ⇐ { 𝕊𝕩: FromPointer ffi.JSON_Object @ }

ffi ⇐ {
 string ← "*u8:c8"
 json_t_ptr ← "*:i8" # struct { type: i32, refcount: u64 }
 opaque_ptr ← "*:i8"

 flags ⇐ {
   reject_duplicates ⇐ 1
   disable_eof_check ⇐ 2
   decode_any ⇐ 4
   decode_int_as_real ⇐ 8
   allow_nul ⇐ 16
   default ⇐ 31 # default to setting everything
 }

 types ⇐ ⟨"object", "array", "string", "integer", "real", "true", "false", "null"⟩
 
 #json_incref ⇐ path •FFI ⟨json_t_ptr, "json_incref", '>' ∾ json_t_ptr⟩
 #json_decref ⇐ path •FFI ⟨"", "json_decref", '>' ∾ json_t_ptr⟩
 json_true ⇐ path •FFI ⟨json_t_ptr, "json_true"⟩
 json_false ⇐ path •FFI ⟨json_t_ptr, "json_false"⟩
 json_null ⇐ path •FFI ⟨json_t_ptr, "json_null"⟩

 json_string ⇐ path •FFI ⟨json_t_ptr, "json_string", string⟩
 json_stringn ⇐ path •FFI ⟨json_t_ptr, "json_stringn", string, "i32"⟩
 json_string_value ⇐ path •FFI ⟨"*:i8", "json_string_value", '>' ∾ json_t_ptr⟩
 json_string_set ⇐ path •FFI ⟨"i32", "json_string_set", json_t_ptr, string⟩
 json_string_setn ⇐ path •FFI ⟨"i32", "json_string_setn", json_t_ptr, string, "i32"⟩

 json_integer ⇐ path •FFI ⟨json_t_ptr, "json_integer", ">i64"⟩
 json_integer_value ⇐ path •FFI ⟨"i64", "json_integer_value", '>' ∾ json_t_ptr⟩
 json_integer_set ⇐ path •FFI ⟨"i32", "json_integer_set", json_t_ptr, "i64"⟩

 json_real ⇐ path •FFI ⟨json_t_ptr, "json_real", ">f64"⟩
 json_real_value ⇐ path •FFI ⟨"f64", "json_real_value", '>' ∾ json_t_ptr⟩
 json_number_value ⇐ path •FFI ⟨"f64", "json_number_value", '>' ∾ json_t_ptr⟩
 json_real_set ⇐ path •FFI ⟨"i32", "json_real_set", json_t_ptr, "f64"⟩

 json_array ⇐ path •FFI ⟨json_t_ptr, "json_array"⟩
 json_array_size ⇐ path •FFI ⟨"u64", "json_array_size", '>' ∾ json_t_ptr⟩
 json_array_get ⇐ path •FFI ⟨json_t_ptr, "json_array_get", json_t_ptr, "u64"⟩
 # this is static INLINE in the C, so not exported...
 #json_array_set ⇐ path •FFI ⟨"i32", "json_array_set", json_t_ptr, "u64", json_t_ptr⟩
 json_array_set_new ⇐ path •FFI ⟨"i32", "json_array_set_new", json_t_ptr, "u64", json_t_ptr⟩
 json_array_set ⇐ json_array_set_new
 #json_array_append ⇐ path •FFI ⟨"i32", "json_array_append", json_t_ptr, json_t_ptr⟩
 json_array_append_new ⇐ path •FFI ⟨"i32", "json_array_append_new", json_t_ptr, json_t_ptr⟩
 json_array_append ⇐ json_array_append_new
 #json_array_insert ⇐ path •FFI ⟨"i32", "json_array_insert", json_t_ptr, "u64", json_t_ptr⟩
 json_array_insert_new ⇐ path •FFI ⟨"i32", "json_array_insert_new", json_t_ptr, "u64", json_t_ptr⟩
 json_array_insert ⇐ json_array_insert_new
 json_array_remove ⇐ path •FFI ⟨"i32", "json_array_remove", json_t_ptr, "u64"⟩
 json_array_clear ⇐ path •FFI ⟨"i32", "json_array_clear", '>' ∾ json_t_ptr⟩
 json_array_extend ⇐ path •FFI ⟨"i32", "json_array_extend", json_t_ptr, json_t_ptr⟩

 json_object ⇐ path •FFI ⟨json_t_ptr, "json_object"⟩
 json_object_size ⇐ path •FFI ⟨"u64", "json_object_size", '>' ∾ json_t_ptr⟩
 json_object_get ⇐ path •FFI ⟨json_t_ptr, "json_object_get", json_t_ptr, string⟩
 #json_object_set ⇐ path •FFI ⟨"i32", "json_object_set", json_t_ptr, string, json_t_ptr⟩
 json_object_set_new ⇐ path •FFI ⟨"i32", "json_object_set_new", json_t_ptr, string, json_t_ptr⟩
 json_object_set ⇐ json_object_set_new
 #json_object_set_nocheck ⇐ path •FFI ⟨"i32", "json_object_set_nocheck", json_t_ptr, string, json_t_ptr⟩
 #json_object_set_new_nocheck ⇐ path •FFI ⟨"i32", "json_object_set_new_nocheck", json_t_ptr, string, json_t_ptr⟩
 json_object_del ⇐ path •FFI ⟨"i32", "json_object_del", json_t_ptr, string⟩
 json_object_clear ⇐ path •FFI ⟨"i32", "json_object_clear", '>' ∾ json_t_ptr⟩
 json_object_update ⇐ path •FFI ⟨"i32", "json_object_update", json_t_ptr, json_t_ptr⟩
 json_object_update_existing ⇐ path •FFI ⟨"i32", "json_object_update_existing", json_t_ptr, json_t_ptr⟩
 json_object_update_missing ⇐ path •FFI ⟨"i32", "json_object_update_missing", json_t_ptr, json_t_ptr⟩

 json_object_iter ⇐ path •FFI ⟨opaque_ptr, "json_object_iter", '>' ∾ json_t_ptr⟩
 json_object_iter_next ⇐ path •FFI ⟨opaque_ptr, "json_object_iter_next", json_t_ptr, opaque_ptr⟩
 json_object_iter_key ⇐ path •FFI ⟨opaque_ptr, "json_object_iter_key", '>' ∾ opaque_ptr⟩
 json_object_iter_value ⇐ path •FFI ⟨json_t_ptr, "json_object_iter_value", '>' ∾ opaque_ptr⟩
 #json_object_iter_set ⇐ path •FFI ⟨"i32", "json_object_iter_set", json_t_ptr, opaque_ptr, json_t_ptr⟩
 json_object_iter_set_new ⇐ path •FFI ⟨"i32", "json_object_iter_set_new", json_t_ptr, opaque_ptr, json_t_ptr⟩
 json_object_iter_set ⇐ json_object_iter_set_new

 json_dumps ⇐ path •FFI ⟨string, "json_dumps", json_t_ptr, "u64"⟩
 json_dump_file ⇐ path •FFI ⟨"i32", "json_dump_file", json_t_ptr, string, "u64"⟩

 json_loads ⇐ path •FFI ⟨json_t_ptr, "json_loads", string, "u64", opaque_ptr⟩
 json_loadb ⇐ path •FFI ⟨json_t_ptr, "json_loadb", string, "u64", "u64", opaque_ptr⟩
 json_load_file ⇐ path •FFI ⟨json_t_ptr, "json_load_file", string, "u64", opaque_ptr⟩

 json_copy ⇐ path •FFI ⟨json_t_ptr, "json_copy", '>' ∾ json_t_ptr⟩
 json_deep_copy ⇐ path •FFI ⟨json_t_ptr, "json_deep_copy", '>' ∾ json_t_ptr⟩
 json_delete ⇐ path •FFI ⟨"", "json_delete", '>' ∾ json_t_ptr⟩
}
