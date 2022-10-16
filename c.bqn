string ← "*u8:c8"
opaque_ptr ← "*:i8"

fopen ⇐ @ •FFI ⟨opaque_ptr, "fopen", string, string⟩
fclose ⇐ @ •FFI ⟨"", "fclose", '>' ∾ opaque_ptr⟩
strlen ⇐ @ •FFI ⟨"u64", "strlen", '>' ∾ opaque_ptr⟩ 

makeI32Vec ⇐ @ •FFI ⟨"a", "bqn_makeI32Vec", "u64", opaque_ptr⟩
makeUTF8Str ⇐ @ •FFI ⟨"a", "bqn_makeUTF8Str", "u64", opaque_ptr⟩
From_CString ⇐ MakeUTF8Str ∘ (StrLen ⋈ ⊢)
