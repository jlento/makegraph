#!/usr/bin/env awk

BEGIN {
    fontsize = 12
    depthspacing = 400
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

/^#node / {
    depth[$2] = $3
    vnodes[$3]++
    for (i=4;i<=NF;i++) class[$2] = class[$2] " " $i
    class[$2] = uniq_words(class[$2] " node")
    next
}

/ *: */ {
    split($0,a,/ *: */)
    deps[a[1]] = a[2]
}

END {
    for (i in depth)
        if(depth[i] > maxdepth)
            maxdepth = depth[i]
    for (i in vnodes)
        if(vnodes[i] > maxvnodes)
            maxvnodes = vnodes[i]

#    printf("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 %d %d\">\n",
#           1.1 * (maxdepth + 2) * depthspacing, maxvnodes * 1.6 * fontsize)
    printf("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\">\n",
           1.1 * (maxdepth + 2) * depthspacing, (maxvnodes + 1) * 1.6 * fontsize)
    printf("  <defs>\n")
    printf("    <style type=\"text/css\"><![CDATA[\n")
    while (getline < css) print $0
    printf("    ]]></style>\n")
    printf("    <filter x=\"0\" y=\"0\" width=\"1\" height=\"1\" id=\"solid\">\n")
    printf("      <feFlood flood-color=\"white\"/>\n")
    printf("      <feComposite in=\"SourceGraphic\"/>\n")
    printf("    </filter>")
    printf("  </defs>\n")
#    printf("  <g transform=\"translate(100,100)\">\n")

    for (i in deps) {
        x[i] = (maxdepth - depth[i] + 1) * depthspacing
    }
    PROCINFO["sorted_in"] = "@ind_str_asc"
    for (i in depth) {
        nv[depth[i]]++
        y[i] = (nv[depth[i]] + 0.5 * maxvnodes - 0.5 * vnodes[depth[i]]) * 1.5 * fontsize
    }

    for (i in deps) {
        if (split(deps[i],a))
            for (j in a)
                printf("  <path class=\"%s\" d=\"M %d,%d C %d,%d %d,%d %d,%d\"/>\n",
                       (index("phony",class[i] " " class[j]) ? "phony" : class[i]),
                       x[i], y[i], (x[i]+x[a[j]])/2, y[i],
                       (x[i]+x[a[j]])/2, y[a[j]], x[a[j]], y[a[j]])
    }
    for (i in deps) {
        printf("  <g class=\"%s\" transform=\"translate(%d,%d)\">\n",
               class[i], x[i], y[i])
        printf("    <circle r=\"%d\"/>\n", fontsize/2)
        printf("    <text x=\"%d\" dy=\".25em\" text-anchor=\"%s\">%s</text>\n",
               deps[i] ? 1.2*fontsize : -1.2 * fontsize,
               (deps[i] ? "start" : "end"), gensub(/^.*\//,"","1",i))
        printf("    <text class=\"fullname\" x=\"%d\" dy=\".25em\" text-anchor=\"%s\">%s</text>\n",
               deps[i] ? 1.2*fontsize : -1.2 * fontsize,
               (deps[i] ? "start" : "end"), i)
        printf("  </g>\n")
    }

#    printf("  </g>\n")
    printf("</svg>\n")
}
