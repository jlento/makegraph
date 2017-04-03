d3.json("makegraph.json", function(error, makedbs) {
    if (error) throw error;

    makedbs.updateDepths = function (m, t) {
        var ip, p;
        if (!("depth" in this[m].targets[t])) {
            makedbs[m].targets[t].depth = 0;
        }
        for (ip in this[m].targets[t].prereqs) {
            p = this[m].targets[t].prereqs[ip];
            if (!("depth" in this[m].targets[p])) {
                this[m].targets[p].depth = this[m].targets[t].depth + 1;
            } else if (this[m].targets[p].depth < this[m].targets[t].depth + 1) {
                this[m].targets[p].depth = this[m].targets[t].depth + 1;
                this.updateDepths(m, p);
            }
        }
    };

    //    for (m in makedbs) {
    var m = 0;
    var t;

    for (t in makedbs[m].targets) {
        makedbs.updateDepths(m, t);
    }

    makedbs[m].ntargetsAtDepth = [];
    for (t in makedbs[m].targets) {
        makedbs[m].ntargetsAtDepth[makedbs[m].targets[t].depth] =
            makedbs[m].ntargetsAtDepth[makedbs[m].targets[t].depth] + 1 || 1;;
    }

    makedbs[m].ntargetsAtDepthMax = Math.max.apply(null,makedbs[m].ntargetsAtDepth);

    var ay = makedbs[m].ntargetsAtDepth.map(function(v,i,a) {
        return (makedbs[m].ntargetsAtDepthMax - v) / 2;
    });
    var iy = makedbs[m].ntargetsAtDepth.map(function(v,i,a) {
        return 0;
    });

    var graph = {nodes: []};

    for (t in makedbs[m].targets) {
        graph.nodes.push({
            id : t,
            x : 100 * (makedbs[m].ntargetsAtDepth.length -
                       makedbs[m].targets[t].depth),
            y : 30 * ((iy[makedbs[m].targets[t].depth]++) +
                      ay[makedbs[m].targets[t].depth] + 1)
        });
    }

    var width = (makedbs[m].ntargetsAtDepth.length + 1) * 100,
        height = (makedbs[m].ntargetsAtDepthMax + 1) * 30;


    var svg = d3.select("body")
            .append("svg")
            .attr("preserveAspectRatio", "xMinYMin meet")
            .attr("viewBox", "0 0 " + width + " " + height);

    var node = svg
            .selectAll("g")
            .data(graph.nodes)
            .enter().append("g");

    node.append("circle")
        .attr("cx", function (d) { return d.x; })
        .attr("cy", function (d) { return d.y; })
        .attr("r", function (d) { return 3; })
        .style("fill", function(d) { return "blue"; });

    node.append("text")
        .text(function(d) { return d.id.replace(/^.*\//, ""); })
        .attr("x", function (d) { return d.x; })
        .attr("y", function (d) { return d.y; });


    node.append("title")
        .text(function(d) { return d.id; });


    console.log(graph.nodes);


}
       );
