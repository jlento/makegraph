#!/usr/bin/env awk

# Parse the output of 'make -rpn' to JSON

function fullpaths(root_orig, paths_wordlist,
                   i, root, path, paths_array, result) {
    result = ""
    split(paths_wordlist, paths_array)
    for (i in paths_array) {
        path = paths_array[i]
        root = gensub(/\/$/, "", "g", root_orig)
        if(match(path, /^\//)) {
            result = result " " path
        } else {
            while (sub(/^\.\.\//, "", path)) {
                sub(/\/[^/]*$/, "", root)
            }
            result = result " " root "/" path
        }
    }
    return substr(result, 2)
}

function words_as_list(words) {
    sub(/^ */,"",words)
    sub(/ *$/,"",words)
    if (words)
        return "[\"" gensub(/ +/, "\", \"", "g", words) "\"]"
    else
        return "[]"
}

BEGIN {
    printf("[")
}

END {
    print "\n]"
}

/^# Make data base/ {
    print dbsep "\n  {"
    sep        = ""
    dbsep        = ","
    next
}

/^# Finished Make data base/ {
    readingfiles = 0
    print "\n    }"
    printf("  }")
    next
}

/^CURDIR/ {
    split($0,a,/:= */)
    curdir = a[2]
    printf("    \"%s\" : \"%s\",\n", "curdir", curdir)
    next
}

/^MAKECMDGOALS/ {
    split($0,a,/:= */)
    printf("    \"%s\" : %s,\n", "makecmdgoals",
           words_as_list(fullpaths(curdir, a[2])))
    next
}

/.DEFAULT_GOAL/ {
    split($0,a,/:= */)
    printf("    \"%s\" : \"%s\",\n", "defaultgoal", fullpaths(curdir, a[2]))
    next
}

/^MAKELEVEL/ {
    split($0,a,/:= */)
    printf("    \"%s\" : %d,\n", "makelevel", a[2])
    next
}

/^MAKEFILE_LIST/ {
    split($0,a,/:= */)
    printf("    \"%s\" : %s,\n", "makefilelist",
           words_as_list(fullpaths(curdir, a[2])))
    next
}

/^# Files/ {
    readingfiles = 1
    printf("    \"targets\" : {")
    next
}

! readingfiles {
    next
}

/^\t/ || /^\.(PHONY|SUFFIXES|DEFAULT|PRECIOUS|INTERMEDIATE|SECONDARY|SECONDEXPANSION|DELETE_ON_ERROR|IGNORE|LOW_RESOLUTION_TIME|SILENT|EXPORT_ALL_VARIABLES|NOTPARALLEL|ONESHELL|POSIX) *:/{
    next
}

/^ *$/ {
    if (target) {
        print sep
        sep = ","
        printf("      \"%s\" : {\n", fullpaths(curdir, target))
        printf("        \"%s\" : %s,\n", "classes", words_as_list(classes))
        printf("        \"%s\" : %s}", "prereqs",
               words_as_list(fullpaths(curdir, prereqs)))
    }
    target  = ""
    classes = ""
    prereqs = ""
}

/^[^#]/ && / *: */ {
    split($0,a, / *: */)
    target = a[1]
    prereqs = a[2]
}

/^# Not a target:/ {
    classes = classes " not-a-target"
}

/^# *File does not exist/ {
    classes = classes " missing"
}

/^# *Phony target/ {
    classes = classes " phony"
}
