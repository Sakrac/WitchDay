\vice\c1541 -format "bdoing",8 d64 bdoing.d64
\vice\c1541 bdoing.d64 -write ..\bdoing\bdoing.prg @8:"bdoing"
\vice\c1541 bdoing.d64 -write test.snd @8:test.snd
\vice\x64 bdoing.d64
\vice\c1541 bdoing.d64 -extract test*

