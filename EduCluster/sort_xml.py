#!/usr/bin/python3

import xml.etree.ElementTree as ET

# Define the correct PCI order
correct_pci_order = [
    "15:00.0", "16:00.0", "3a:00.0", "3b:00.0",
    "89:00.0", "8a:00.0", "b2:00.0", "b3:00.0"
]

# Define mapping of UUIDs to PCI addresses
uuid_pci_mapping = {
        "67d37d0a-6935-4259-95c4-605ee133bc20": "b3:00.0",
        "8dd97810-8aa2-49dc-a313-622401e59179": "16:00.0",
        "8d040417-9dbc-4951-a3a0-51ee98038845": "3b:00.0",
        "fd0ba89a-9797-4972-b715-7d63a58f78fb": "15:00.0",
        "0b1149b0-6b20-4b34-9f34-a8f96b8a1327": "8a:00.0",
        "1fb65bdd-2eb2-48e6-a41b-6e0fea6c8203": "b3:00.0",
        "66eb456b-c5eb-47c8-8685-d7b3cdbdf4e1": "89:00.0",
        "a7c48a8c-d3d1-48c0-b1d8-b617f4b9f072": "8a:00.0",
        "916760f1-0a93-4d0d-b98d-2e5df0c774c6": "3a:00.0",
        "b0a86cd2-4be1-47bc-bd90-0628822d2d28": "16:00.0",
        "8b8471a2-15ca-4906-9f5e-a818bcead394": "3b:00.0",
        "425bb12a-688c-4900-aa27-e3887d0a253b": "b2:00.0",
        "dcf09294-d6d1-4602-8c7e-6af3a9f9b8cd": "b2:00.0",
        "54909753-3b42-41c5-96c3-4f0ebf5ca6c8": "15:00.0",
        "fc41cb19-488f-4aba-8f3c-bfb97254ed74": "89:00.0",
        "39fb56a7-cedb-4372-ae59-56e373c78d4e": "3a:00.0"
}

# Sort UUIDs according to the correct PCI order
sorted_uuids = sorted(uuid_pci_mapping.keys(), key=lambda x: correct_pci_order.index(uuid_pci_mapping[x]))

# Create the root XML element
devices = ET.Element("devices")

# Generate the formatted XML
for uuid in sorted_uuids:
    hostdev = ET.SubElement(devices, "hostdev", mode="subsystem", type="mdev", model="vfio-pci")
    source = ET.SubElement(hostdev, "source")
    ET.SubElement(source, "address", uuid=uuid)

# Convert the XML tree into a properly formatted string
xml_str = ET.tostring(devices, encoding="utf-8").decode("utf-8")

# Manually add indentation for readability
from xml.dom.minidom import parseString
formatted_xml = parseString(xml_str).toprettyxml(indent="    ")

# Write the formatted XML to a file
with open("sorted_xml.txt", "w") as file:
    file.write(formatted_xml)

print("✅ XML successfully formatted and saved as 'sorted_xml.txt'.")