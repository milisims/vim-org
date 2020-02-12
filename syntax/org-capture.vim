syntax clear

syntax match orgCaptureKey1 /^\s*\S/ nextgroup=orgCaptureKey2,orgCaptureDescription skipwhite
syntax match orgCaptureKey2 /\S/ nextgroup=orgCaptureKey3,orgCaptureDescription skipwhite
syntax match orgCaptureKey3 /\S/ nextgroup=orgCaptureKey4,orgCaptureDescription skipwhite
syntax match orgCaptureKey4 /\S/ nextgroup=orgCaptureKey5,orgCaptureDescription skipwhite
syntax match orgCaptureKey5 /\S/ nextgroup=orgCaptureKey6,orgCaptureDescription skipwhite
syntax match orgCaptureKey6 /\S/ nextgroup=orgCaptureKey4,orgCaptureDescription skipwhite
syntax match orgCaptureDescription /\s\zs\S.*$/ contained

syntax match orgCaptureTitle /^\s*Capture:.*$/

syntax cluster orgCaptureKeys contains=orgCaptureKey1,orgCaptureKey2,orgCaptureKey3
syntax cluster orgCaptureKeys add=orgCaptureKey4,orgCaptureKey5,orgCaptureKey6

highlight link orgCaptureKey1 Character
highlight link orgCaptureKey2 Number
highlight link orgCaptureKey3 Boolean
highlight link orgCaptureKey4 Character
highlight link orgCaptureKey5 Number
highlight link orgCaptureKey6 Boolean

highlight link orgCaptureTitle Comment
highlight link orgCaptureDescription Constant
