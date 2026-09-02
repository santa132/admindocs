# Guideline

## Creating a single vGPU

- Get the ID of the graphic card (first column)

```bash
lspci | grep NVIDIA
```

- Run the script
  - `-g`: ID of the graphic card
  - `-r`: RAM amount of vGPU (4/8/16)

```bash
sudo ./aimc-create-vgpu.sh -g 15:00.0 -r 8
```

## Creating all vGPUs

- Run the script
  - `-r`: RAM amount of vGPU (4/8/16)

```bash
sudo ./aimc-create-all-vgpus.sh -r 8
```

- **NOTE**: The `aimc-create-vgpu.sh` should be located at the same folder.

## Delete a single vGPU

- Get the ID of the vGPU

```bash
mdevctl list
```

- Run the script
  - `-g`: vGPU ID

```bash
sudo ./aimc-delete-vgpu.sh -g f3e76fa7-47c0-40f4-93d8-d6cd1373efc1
```


## Others

### Generate vGPU xml, use at 03_vGPU.md

vGPU_generate_xml.sh

### Create virtual node

create_venx.sh
