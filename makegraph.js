const type = function(obj) {
    return Object.prototype.toString.call(obj)
        .replace(/(^.* |]$)/g,"");
};

const lastword = function(str, sep) {
    if (sep) {
        return str.split(sep).slice(-1)[0];
    }else {
        return str.split().slice(-1)[0];
    }
};

class MakeGraph {

    constructor(arrayOfMakeDataBases, boolOnlyGoalDeps) {

        function addNode(makedb, target, graph) {
            if(!(target in graph)) {
                graph[target] = {
                    children : makedb.targets[target].prereqs || [],
                    classes  : makedb.targets[target].classes || [],
                    depth : 0};
                for(let prereq of makedb.targets[target].prereqs) {
                    addNode(makedb, prereq, graph);
                }
            }
        }

        function updateDepth(parent, graph) {
            for (let child of graph[parent].children) {
                if(graph[child].depth < graph[parent].depth + 1) {
                    graph[child].depth = graph[parent].depth + 1;
                    updateDepth(child, graph);
                }
            }
        }

        for (let m of arrayOfMakeDataBases) {
            var roots;
            if(boolOnlyGoalDeps) {
                if(m.makecmdgoals) {
                    roots = m.makecmdgoals;
                } else {
                    roots = [m.defaultgoal];
                }
            } else {
                roots = Object.keys(m.targets);
            }

            for (let target of roots) {
                m.targets[target].classes.push("goal");
                addNode(m, target, this);
            }
            for (let node of roots) {
                updateDepth(node, this);
            }
        }
    }
}

//d3.json("makegraph.json", function(error, makedbs) {
//    if (error) throw error;

    const charWidth = 12;

    //var graph = new MakeGraph(makedbs);
    var graph = new MakeGraph(makedbs, true);


    var arrayOfDepths = Object.values(graph).map(a=>a.depth);
    var nTargetsAtDepth = arrayOfDepths.reduce((
        (acc,e) => {
            acc[e]++ || (acc[e] = 1);
            return acc;
        }), []);
    var depthMax = nTargetsAtDepth.length;
    var nTargetsAtDepthMax = Math.max.apply(null,nTargetsAtDepth);
    var columnTopShift = nTargetsAtDepth.map(
        v => (nTargetsAtDepthMax - v) / 2);
    var targetMaxWidthAtDepth = [];
    for (let i = 0; i < depthMax; i++) {
        targetMaxWidthAtDepth[i] =
            Math.max.apply(null,
                           Object.keys(graph)
                           .filter(k => graph[k].depth == i)
                           .map(k => lastword(k, "/").length));
    }
    var columnWidth = [targetMaxWidthAtDepth[0]];
    for (let i = 1; i < depthMax; i++) {
        columnWidth.push(
            targetMaxWidthAtDepth[i - 1] + targetMaxWidthAtDepth[i]);
    }
    columnWidth.push(targetMaxWidthAtDepth[depthMax - 1]);
    columnWidthCumulative = [];
    columnWidth.reduce(
        (a, v, i) => columnWidthCumulative[i] = a + v, 0);

    var nodes = [], links = [];
    var sortedTargets = Object.keys(graph).sort();
    var iy = nTargetsAtDepth.map(v => (nTargetsAtDepthMax - v) / 2);
    for (var it in sortedTargets) {
        t = sortedTargets[it];
        nodes.push({
            id : t,
            classes : graph[t].classes,
            textAnchor : (graph[t].children.length ? "begin" : "end"),
            x : charWidth * (columnWidthCumulative[depthMax] -
                             columnWidthCumulative[graph[t].depth]),
            y : 30 * (++iy[graph[t].depth])
        });
    }

    for (t in graph) {
        nt = nodes.filter(function(d) {
            return (d.id === t);
        })[0];
        for (ip in graph[t].children) {
            p = graph[t].children[ip];
            np = nodes.filter(function(d) {
                return (d.id === p);
            })[0];
            links.push({
                x0 : nt.x, y0 : nt.y,
                x1 : np.x, y1 : np.y});
        }
    }

    var width = charWidth * columnWidth.reduce((a, v) => a + v, 0),
        height = (nTargetsAtDepthMax + 1) * 30;

    var ww = document.getElementById('body').offsetWidth - 4,
        wh = window.innerHeight - 4;

    var svg = d3.select("body").append("svg")
            .attr("width", ww)
            .attr("height", wh)
            .append("g")
            .attr("transform", "translate(" +
                  (ww/width < wh/height ? 0 : (ww - width * wh / height) / 2) +
                  "," +
                  (ww/width < wh/height ? (wh - height * ww / width) / 2: 0) +
                  ")scale(" +
                  Math.min(ww/width, wh/height) +
                  ")")
            .call(d3.behavior.zoom().on("zoom", zoom))
            .append("g");

        //.call(d3.behavior.zoom().scaleExtent([1, 8]).on("zoom", zoom))

    //.attr("preserveAspectRatio", "xMinYMin meet")
    //.attr("viewBox", "0 0 " + width + " " + height);

    svg.append("rect")
        .attr("class", "overlay")
        .attr("width", width)
        .attr("height", height);

    var link = svg
            .selectAll("path")
            .data(links)
            .enter()
            .append("path")
            .attr("d", function(d) {
                return "M " + d.x0 + "," + d.y0 +
                    " C " + ((d.x0 + d.x1)/2) + "," + d.y0 +
                    " " + ((d.x0 + d.x1)/2) + "," + d.y1 +
                    " " + d.x1 + "," +d.y1; });

    var node = svg
            .selectAll("g")
            .data(nodes)
            .enter()
            .append("g")
            .attr("class", d => d.classes.join(" "))
            .attr("transform", function(d) {
                return "translate(" + d.x + "," + d.y + ")";});

    node.append("circle")
        .attr("r", _ => 5)
        .style("fill", d => d.classes.includes("goal") ? "black" : "white");

    node.append("text")
        .text(function(d) { return lastword(d.id, "/"); })
        .attr("x", function (d) {
            return  (d.textAnchor === "end" ? -12 : 12); })
        .attr("y", 3)
        .attr("text-anchor", function(d) { return d.textAnchor; });

    node.append("title")
        .text(function(d) { return d.id; });

    function zoom() {
        svg.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
    }

//}
//       );
