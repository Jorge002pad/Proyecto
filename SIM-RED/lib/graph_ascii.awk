#!/usr/bin/gawk -f
# SIM-RED EXTENDIDO - ASCII Graph Generator
# Generates ASCII bar charts and line graphs from data

BEGIN {
    # Default settings
    if (width == 0) width = 60
    if (height == 0) height = 20
    if (char == "") char = "█"
    
    max_value = 0
    count = 0
}

# Read data
{
    if (NF >= 1) {
        values[count] = $1
        if (NF >= 2) {
            labels[count] = $2
        } else {
            labels[count] = count + 1
        }
        
        if ($1 > max_value) {
            max_value = $1
        }
        count++
    }
}

END {
    if (count == 0) {
        print "No data to display"
        exit
    }
    
    # Generate bar chart
    if (type == "bar" || type == "") {
        print_bar_chart()
    }
    # Generate line graph
    else if (type == "line") {
        print_line_graph()
    }
    # Generate histogram
    else if (type == "hist") {
        print_histogram()
    }
}

function print_bar_chart() {
    print ""
    print "┌" repeat("─", width + 2) "┐"
    
    for (i = 0; i < count; i++) {
        # Calculate bar length
        if (max_value > 0) {
            bar_len = int((values[i] / max_value) * width)
        } else {
            bar_len = 0
        }
        
        # Print label
        printf "│%-10s ", substr(labels[i], 1, 10)
        
        # Print bar
        for (j = 0; j < bar_len; j++) {
            printf "%s", char
        }
        
        # Print value
        printf " %.2f", values[i]
        
        # Fill remaining space
        remaining = width - bar_len - length(sprintf(" %.2f", values[i]))
        for (j = 0; j < remaining; j++) {
            printf " "
        }
        
        print "│"
    }
    
    print "└" repeat("─", width + 2) "┘"
    print ""
}

function print_line_graph() {
    # Create 2D array for graph
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            graph[y][x] = " "
        }
    }
    
    # Plot points
    for (i = 0; i < count; i++) {
        x = int((i / (count - 1)) * (width - 1))
        
        if (max_value > 0) {
            y = height - 1 - int((values[i] / max_value) * (height - 1))
        } else {
            y = height - 1
        }
        
        if (y >= 0 && y < height && x >= 0 && x < width) {
            graph[y][x] = "●"
            
            # Connect with lines
            if (i > 0) {
                prev_x = int(((i-1) / (count - 1)) * (width - 1))
                prev_y = height - 1 - int((values[i-1] / max_value) * (height - 1))
                
                # Simple line drawing
                if (prev_y < y) {
                    for (yy = prev_y + 1; yy < y; yy++) {
                        graph[yy][x] = "│"
                    }
                } else if (prev_y > y) {
                    for (yy = y + 1; yy < prev_y; yy++) {
                        graph[yy][prev_x] = "│"
                    }
                }
            }
        }
    }
    
    # Print graph
    print ""
    printf "%.2f ┤", max_value
    for (x = 0; x < width; x++) {
        printf "%s", graph[0][x]
    }
    print ""
    
    for (y = 1; y < height - 1; y++) {
        printf "      │"
        for (x = 0; x < width; x++) {
            printf "%s", graph[y][x]
        }
        print ""
    }
    
    printf "%.2f ┤", 0.0
    for (x = 0; x < width; x++) {
        printf "%s", graph[height-1][x]
    }
    print ""
    
    printf "      └"
    for (x = 0; x < width; x++) {
        printf "─"
    }
    print "┘"
    print ""
}

function print_histogram() {
    # Calculate bins
    bins = 10
    bin_width = max_value / bins
    
    for (i = 0; i < bins; i++) {
        bin_count[i] = 0
    }
    
    # Count values in each bin
    for (i = 0; i < count; i++) {
        bin = int(values[i] / bin_width)
        if (bin >= bins) bin = bins - 1
        bin_count[bin]++
    }
    
    # Find max bin count
    max_bin = 0
    for (i = 0; i < bins; i++) {
        if (bin_count[i] > max_bin) {
            max_bin = bin_count[i]
        }
    }
    
    # Print histogram
    print ""
    for (i = 0; i < bins; i++) {
        range_start = i * bin_width
        range_end = (i + 1) * bin_width
        
        printf "[%6.1f-%6.1f] ", range_start, range_end
        
        if (max_bin > 0) {
            bar_len = int((bin_count[i] / max_bin) * width)
        } else {
            bar_len = 0
        }
        
        for (j = 0; j < bar_len; j++) {
            printf "%s", char
        }
        
        printf " %d\n", bin_count[i]
    }
    print ""
}

function repeat(str, n) {
    result = ""
    for (i = 0; i < n; i++) {
        result = result str
    }
    return result
}
