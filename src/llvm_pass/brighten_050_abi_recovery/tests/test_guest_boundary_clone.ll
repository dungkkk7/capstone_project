target triple = "x86_64-pc-linux-gnu"

@sink = global i64 0

define ptr @sub_pinned(ptr %state, i64 %pc, ptr %memory) noinline {
entry:
  store i64 1, ptr @sink, align 8
  ret ptr %state
}

define ptr @sub_plain(ptr %state, i64 %pc, ptr %memory) {
entry:
  store i64 2, ptr @sink, align 8
  ret ptr %state
}

define ptr @caller(ptr %state, i64 %pc, ptr %memory) {
entry:
  %pinned = call ptr @sub_pinned(ptr %state, i64 %pc, ptr %memory)
  %plain = call ptr @sub_plain(ptr %state, i64 %pc, ptr %memory)
  %result = select i1 true, ptr %pinned, ptr %plain
  ret ptr %result
}
