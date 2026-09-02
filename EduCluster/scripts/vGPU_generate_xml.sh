#!/bin/bash

# Read input from mdevctl list command -> OLD
# mdevctl list | while read -r line; do
    # uuid=$(echo "$line" | awk '{print $1}')
    # echo "    <hostdev mode='subsystem' type='mdev' model='vfio-pci'>"
    # echo "      <source>"
    # echo "        <address uuid='$uuid'/>"
    # echo "      </source>"
    # echo "    </hostdev>"
# done

# New version from Mar25
# Output file
output_file="xml.txt"

# Write XML header and opening <device> tag
echo "<device>" > "$output_file"

# Read input from mdevctl list command and generate XML content
mdevctl list | while read -r line; do
    uuid=$(echo "$line" | awk '{print $1}')
    echo "    <hostdev mode=\"subsystem\" type=\"mdev\" model=\"vfio-pci\">" >> "$output_file"
    echo "        <source>" >> "$output_file"
    echo "            <address uuid=\"$uuid\"/>" >> "$output_file"
    echo "        </source>" >> "$output_file"
    echo "    </hostdev>" >> "$output_file"
done

# Close the <device> tag
echo "</device>" >> "$output_file"

echo "✅ XML file 'xml.txt' has been successfully created."