# `Step to grab image DGX`
## 1. Clone the old image → create a new image
- Go to: Provisioning → Software images → Clone
- Name the new image (e.g., newimage)
- Use Grab to image → Other Image to save the current node’s state into newimage

## 2. Clone the category → create a new category
- Go to: Grouping → Categories → Clone
- Name the new category (e.g., newcategory)
- In the settings of newcategory:
- → change "Software image" to newimage

## 3. Assign a few test nodes to the new category
- Go to: Devices → Nodes → Edit → Settings → Category
- Select newcategory
- Save

## 4️. Reboot the test nodes
- The nodes will PXE boot from the new image


# `Grab images Trinity`
## Clone image on dashboard: 
- Go to OS images -> select image to clone -> Clone image: ubuntu-24-gpu-v1-Prod-gn2

- Grab node to new image:
```
Ex: luna node osgrab --nodry -o ubuntu-24-gpu-v1-Prod-gn2 -v aimc-gn2
```

Pack image: 
```
luna osimage pack ubuntu-24-gpu-v1-Prod-gn2 
```

## Point to new image: 
- Go to Nodes 
- Select node to change
- Edit OS image
- Reboot

## Grab image on control node (aimc-ctrl1 / aimc-ctrl2)
### All commands run on control node
- GN node
```
Grab image
luna node osgrab --nodry -o ubuntu-24-gpu-v1-Prod-gn aimc-gn2
Pack the image
luna osimage pack ubuntu-24-gpu-v1-Prod-gn
```

- GNA node
```
Grab image
luna node osgrab --nodry -o ubuntu-24-gpu-v1-Prod-gna aimc-gna1
Pack the image
luna osimage pack ubuntu-24-gpu-v1-Prod-gna
```

- H100 node
```
Grab image
luna node osgrab --nodry -o ubuntu-24-gpu-v1-Prod-h100 aimc-h100-02
Pack the image
luna osimage pack ubuntu-24-gpu-v1-Prod-h100
```