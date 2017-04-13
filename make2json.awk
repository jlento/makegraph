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
    pidstack[0] = 0
    mypid = 0
}

END {
    print "\n]"
#    for(i in subreqs) {
#        for(j in subreqs[i]) {
#            if(subreqs[i][j]) {
#                print "pid: " i " target: " j " subreqs: " subreqs[i][j]
#            }
#        }
#    }
}

/^Live child/ {
    mypid = $NF
    pidstack[length(pidstack)] = mypid
    targetstack[length(pidstack)-2] = gensub(/(^.+\()(.*)(\).+$)/,"\\2","g",$0)
#    print "livechild: " targetstack[length(pidstack)-2]
    next
}

/^Reaping (winning|losing) child/ {
#    for(i in pidstack) {
#        print "i: " i " pidstack[i]: " pidstack[i]
#    }
#    print "pidstack mypid: " mypid
    delete pidstack[length(pidstack)-1]
    mypid = pidstack[length(pidstack)-1]
#    for(i in pidstack) {
#        print "i: " i " pidstack[i]: " pidstack[i]
#    }
#    print "pidstack mypid: " mypid
    next
}

/^# Make data base/ {
    print dbsep "\n  {"
    sep        = ""
    dbsep        = ","
    makecmdgoals = ""
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
    makecmdgoals = a[2]
    printf("    \"%s\" : %s,\n", "makecmdgoals",
           words_as_list(fullpaths(curdir, makecmdgoals)))
    next
}

/\.DEFAULT_GOAL/ {
    split($0,a,/:= */)
    printf("    \"%s\" : \"%s\",\n", "defaultgoal", fullpaths(curdir, a[2]))
    if(makecmdgoals) {
#        print "goal: "makecmdgoals
        subreqs[pidstack[length(pidstack)-2]][targetstack[length(pidstack)-2]] = subreqs[pidstack[length(pidstack)-2]][targetstack[length(pidstack)-2]] " " makecmdgoals
    } else {
#        print "defgoal: " a[2]
        subreqs[pidstack[length(pidstack)-2]][targetstack[length(pidstack)-2]] = subreqs[pidstack[length(pidstack)-2]][targetstack[length(pidstack)-2]] " " a[2]
    }
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
        printf("        \"%s\" : %s}\n", "prereqs",
               words_as_list(fullpaths(curdir, prereqs " " subreqs[mypid][target])))
#        printf("        \"%s\" : %s}", "subreqs",
#               words_as_list(fullpaths(curdir, subreqs[mypid][target])))
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
