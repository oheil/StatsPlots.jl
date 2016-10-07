@userplot CornerPlot

@recipe function f(cp::CornerPlot; compact=false, maxvariables=30, histpct = 0.1)
    mat = cp.args[1]
    @assert typeof(mat) <: AbstractMatrix
    N = size(mat,2)
    if N > maxvariables
        error("Requested to plot $N variables in $(N^2) subplots!  Likely, the first input needs transposing, otherwise increase maxvariables.")
    end

    # k is the number of rows/columns to hide
    k = compact ? 1 : 0

    # n is the total number of rows/columns.  hists always shown
    n = N + 1 - k

    labs = pop!(d, :label, ["x$i" for i=1:N])
    if labs!=[""] && length(labs)!=N
        error("Number of labels not identical to number of datasets")
    end

    # build a grid layout, where the histogram sizes are a fixed percentage, and we
    scatterpcts = ones(n-1) * (1-histpct) / (n-1)
    g = grid(n, n, widths = vcat(scatterpcts, histpct), heights = vcat(histpct, scatterpcts))
    spidx = 1
    indices = zeros(Int,n,n)
    for i=1:n, j=1:n
        isblank = (i==1 && j==n) || (compact && i>1 && j<n && j>=i)
        g[i,j].attr[:blank] = isblank
        if !isblank
            indices[i,j] = spidx
            spidx += 1
        end
    end
    layout := g

    # some defaults
    legend    := false
    foreground_color_border := nothing
    margin    --> 1mm
    titlefont --> font(11)
    fillcolor --> Plots.fg_color(d)
    linecolor --> Plots.fg_color(d)
    grid      --> true
    ticks     := nothing
    formatter := v->""
    link      := :both

    # figure out good defaults for scatter plot dots:
    pltarea = 1 / (2n)
    nsamples = size(mat,1)
    markersize  --> clamp(pltarea * 1000 / sqrt(nsamples), 1,     10)
    markeralpha --> clamp(pltarea * 100 / nsamples^0.42,   0.005, 0.4)

    # histograms in the right column
    for i=1:N
        compact && i == 1 && continue
        @series begin
            orientation := :h
            seriestype  := :histogram
            subplot     := indices[i+1-k,n]
            grid        := false
            view(mat,:,i)
        end
    end

    # histograms in the top row
    for j=1:N
        compact && j == N && continue
        @series begin
            seriestype  := :histogram
            subplot     := indices[1,j]
            grid        := false
            view(mat,:,j)
        end
    end

    # scatters
    for i=1:N
        vi = view(mat,:,i)
        for j = 1:N
            # only the lower triangle
            if compact && i <= j
                continue
            end

            vj = view(mat,:,j)
            @series begin
                ticks := :auto
                if i == N
                    xformatter := :auto
                    xguide := cycle(labs, j)
                end
                if j == 1
                    yformatter := :auto
                    yguide := cycle(labs, i)
                end
                seriestype := :scatter
                subplot := indices[i+1-k, j]
                smooth --> true
                markerstrokewidth --> 0
                vj, vi
            end
        end
        # end
    end
end