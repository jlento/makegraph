#!/usr/bin/env awk

# Parse the output of 'make -rpn' to JSON

function notdir(path) {
    return gensub(/.*\//,"","g",path)
}

function uniq_words(words,    n,i,a1,a2,result) {
    n = split(words, a1)
    if (n ==0) {
        result ""
    } else if (n == 1) {
        result = a1[1]
    } else {
        for (i in a1)
            a2[a1[i]] = a1[i]
        asort(a2)
        result = a2[1]
        for (i=2;i<=length(a2);i++)
            result = result " " a2[i]
    }
    return result
}

function update_depths(node, deps, depths,    b) {
    if (split(deps[node],b))
        for (i in b)
            if (!(b[i] in depth))
                depth[b[i]] = depth[node] + 1
            else
                if (depth[node] + 1 > depth[b[i]]) {
                    depth[b[i]] = depth[node] + 1
                    update_depths(b[i], deps, depths)
                }
}

function addprefix(prefix, words) {
    return gensub(/[^ ]+/,prefix "&","g",words)
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

/^MAKECMDGOALS/ {
    split($0,a,/:= */)
    printf("    \"%s\" : %s,\n", "makecmdgoals", words_as_list(a[2]))
    next
}

/.DEFAULT_GOAL/ {
    split($0,a,/:= */)
    printf("    \"%s\" : \"%s\",\n", "defaultgoal", a[2])
    next
}

/^CURDIR/ {
    split($0,a,/:= */)
    printf("    \"%s\" : \"%s\",\n", "curdir", a[2])
    next
}

/^MAKELEVEL/ {
    split($0,a,/:= */)
    printf("    \"%s\" : %d,\n", "makelevel", a[2])
    next
}

/^MAKEFILE_LIST/ {
    split($0,a,/:= */)
    printf("    \"%s\" : %s,\n", "makefilelist", words_as_list(a[2]))
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
        printf("      \"%s\" : {\n", target)
        printf("        \"%s\" : %s,\n", "classes", words_as_list(classes))
        printf("        \"%s\" : %s}", "prereqs", words_as_list(prereqs))
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
