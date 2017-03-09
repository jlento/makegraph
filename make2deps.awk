#!/usr/bin/env awk

# Parse the dependencies etc. from the '# Files' sections of the
# output of 'make -rpn'

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

/^# Variables/ {
    goals=""
    next
}

/^MAKECMDGOALS/ {
    split($0,a,/:= */)
    goals=a[2]
}

/.DEFAULT_GOAL/ && ! goals {
    split($0,a,/:= */)
    goals=a[2]
}

/^MAKELEVEL/ {
    split($0,a,/:= */)
    makelevel=a[2]
}

/^# Files/ {
    readingfiles = 1
    outfile="deps-" ifile++ ".txt"
    delete class
    delete depth
    delete deps
    next
}

/^# Finished Make data base/ {
    readingfiles = 0
    print "#goals", goals > outfile
    print "#makelevel", makelevel > outfile
    delete depth[""]
    for (i in deps)
        print i " : " deps[i] > outfile
    for (i in depth)
        print "#node", i, depth[i], class[i] > outfile
}
! readingfiles {
    next
}


/^\t/ || /^\./ {
    next
}

/^ *$/ {
    if (_node) {
        class[_node] = uniq_words(_class)
        if (!(_node in depth))
            depth[_node] = 0
            deps[_node] = uniq_words(_deps)
            update_depths(_node, deps, depths)
    }
    _node  =""
    _class =""
    _deps  =""
}

/^[^#]/ && / *: */ {
    split($0,a, / *: */)
    _node = a[1]
    _deps = a[2]
}

/^# Not a target:/ {
    _class = _class " not-a-target"
}

/^# *File does not exist/ {
    _class = _class " missing"
}

/^# *Phony target/ {
    _class = _class " phony"
}
